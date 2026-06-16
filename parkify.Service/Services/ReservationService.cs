using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using parkify.Model.Exceptions;
using parkify.Model.Models;
using parkify.Model.Requests;
using parkify.Model.SearchObject;
using parkify.RabbitMQ;
using parkify.Service.Interfaces;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;

namespace parkify.Service.Services
{
    public class ReservationService
        : BaseCRUDService<Reservation, ReservationSearch, Database.Reservation, ReservationInsertRequest, ReservationUpdateRequest>,
          IReservationService
    {
        private readonly IMessagePublisher _publisher;

        public ReservationService(
            Database.ParkifyContext context,
            IMapper mapper,
            IMessagePublisher publisher)
            : base(context, mapper)
        {
            _publisher = publisher;
        }

        public override IQueryable<Database.Reservation> AddFilter(
            ReservationSearch search,
            IQueryable<Database.Reservation> query)
        {
            query = base.AddFilter(search, query);

            if (search?.UserId.HasValue == true)
                query = query.Where(x => x.UserId == search.UserId);

            if (search?.ParkingZoneId.HasValue == true)
                query = query.Where(x => x.ParkingZoneId == search.ParkingZoneId);

            if (search?.Status.HasValue == true)
                query = query.Where(x => (int)x.Status == search.Status);


            return query.OrderByDescending(x => x.Created);
        }

        public byte[] GenerateAdminReportPdf(DateTime? from, DateTime? to)
        {
            var start = from?.ToUniversalTime() ?? DateTime.UtcNow.Date.AddDays(-30);
            var end = to?.ToUniversalTime() ?? DateTime.UtcNow;

            if (end < start)
            {
                throw new UserException("Datum završetka mora biti poslije datuma početka izvještaja.");
            }

            var reservations = Context.Reservations
                .Where(x => x.Created >= start && x.Created <= end)
                .Select(x => new
                {
                    x.Id,
                    x.ReservationCode,
                    x.UserId,
                    x.ParkingZoneId,
                    ZoneName = x.ParkingZone.Name,
                    x.Status,
                    x.FinalPrice,
                    x.WalletAmountUsed,
                    x.PaymentAmountPaid,
                    x.Created
                })
                .OrderByDescending(x => x.Created)
                .ToList();

            var payments = Context.Payments
                .Where(x => x.Created >= start && x.Created <= end)
                .Select(x => new
                {
                    x.Id,
                    x.UserId,
                    x.ReservationId,
                    x.Amount,
                    x.Status,
                    x.Created
                })
                .OrderByDescending(x => x.Created)
                .ToList();

            var totalRevenue = payments
                .Where(x => x.Status == Database.PaymentStatus.Completed)
                .Sum(x => x.Amount);

            var totalRefunds = payments
                .Where(x => x.Status == Database.PaymentStatus.Refunded)
                .Sum(x => x.Amount);

            var totalWalletUsage = reservations.Sum(x => x.WalletAmountUsed);
            var totalDirectPayments = reservations.Sum(x => x.PaymentAmountPaid);

            var topZones = reservations
                .GroupBy(x => new { x.ParkingZoneId, x.ZoneName })
                .Select(x => new
                {
                    x.Key.ParkingZoneId,
                    x.Key.ZoneName,
                    ReservationCount = x.Count(),
                    Revenue = x.Sum(y => y.PaymentAmountPaid + y.WalletAmountUsed)
                })
                .OrderByDescending(x => x.ReservationCount)
                .ThenByDescending(x => x.Revenue)
                .Take(5)
                .ToList();

            QuestPDF.Settings.License = LicenseType.Community;

            return Document.Create(container =>
            {
                container.Page(page =>
                {
                    page.Margin(30);
                    page.Size(PageSizes.A4);

                    page.Header().Column(column =>
                    {
                        column.Item().Text("Parkify administrativni izvještaj")
                            .FontSize(20)
                            .SemiBold();
                        column.Item().Text($"Period: {start:dd.MM.yyyy HH:mm} - {end:dd.MM.yyyy HH:mm}")
                            .FontSize(10)
                            .FontColor(Colors.Grey.Darken2);
                    });

                    page.Content().Column(column =>
                    {
                        column.Spacing(12);

                        column.Item().Row(row =>
                        {
                            row.RelativeItem().Element(block => SummaryCard(block, "Rezervacije", reservations.Count.ToString()));
                            row.RelativeItem().Element(block => SummaryCard(block, "Plaćanja", payments.Count.ToString()));
                            row.RelativeItem().Element(block => SummaryCard(block, "Prihod", $"{totalRevenue:F2} KM"));
                            row.RelativeItem().Element(block => SummaryCard(block, "Refundacije", $"{totalRefunds:F2} KM"));
                        });

                        column.Item().Row(row =>
                        {
                            row.RelativeItem().Element(block => SummaryCard(block, "Wallet naplata", $"{totalWalletUsage:F2} KM"));
                            row.RelativeItem().Element(block => SummaryCard(block, "Direktna naplata", $"{totalDirectPayments:F2} KM"));
                            row.RelativeItem().Element(block => SummaryCard(block, "Potvrđene", reservations.Count(x => x.Status == Database.ReservationStatus.Confirmed).ToString()));
                            row.RelativeItem().Element(block => SummaryCard(block, "Otkazane", reservations.Count(x => x.Status == Database.ReservationStatus.Cancelled).ToString()));
                        });

                        column.Item().Text("Najaktivnije zone").FontSize(14).SemiBold();
                        column.Item().Table(table =>
                        {
                            table.ColumnsDefinition(columns =>
                            {
                                columns.RelativeColumn(3);
                                columns.RelativeColumn(1);
                                columns.RelativeColumn(1);
                            });

                            table.Header(header =>
                            {
                                header.Cell().Element(TableHeader).Text("Zona");
                                header.Cell().Element(TableHeader).AlignRight().Text("Rezervacije");
                                header.Cell().Element(TableHeader).AlignRight().Text("Promet");
                            });

                            if (topZones.Any())
                            {
                                foreach (var zone in topZones)
                                {
                                    table.Cell().Element(TableCell).Text(zone.ZoneName);
                                    table.Cell().Element(TableCell).AlignRight().Text(zone.ReservationCount.ToString());
                                    table.Cell().Element(TableCell).AlignRight().Text($"{zone.Revenue:F2} KM");
                                }
                            }
                            else
                            {
                                table.Cell().ColumnSpan(3).Element(TableCell).Text("Nema podataka za odabrani period.");
                            }
                        });

                    });

                    page.Footer().AlignCenter().Text($"Generisano: {DateTime.UtcNow:dd.MM.yyyy HH:mm} UTC").FontSize(9);
                });
            }).GeneratePdf();
        }

        public byte[] GenerateFinanceReportPdf(DateTime? from, DateTime? to, int? userId = null)
        {
            var start = from?.ToUniversalTime() ?? DateTime.UtcNow.Date.AddDays(-30);
            var end = to?.ToUniversalTime() ?? DateTime.UtcNow;

            if (end < start)
            {
                throw new UserException("Datum završetka mora biti poslije datuma početka izvještaja.");
            }

            var userDisplayName = userId.HasValue
                ? Context.Users
                    .Where(x => x.Id == userId.Value)
                    .Select(x => string.IsNullOrWhiteSpace(x.FirstName) && string.IsNullOrWhiteSpace(x.LastName)
                        ? x.Username
                        : $"{x.FirstName} {x.LastName}".Trim())
                    .FirstOrDefault()
                : null;

            if (userId.HasValue && string.IsNullOrWhiteSpace(userDisplayName))
            {
                throw new UserException("Odabrani korisnik nije pronađen.");
            }

            var payments = Context.Payments
                .Where(x => x.Created >= start && x.Created <= end)
                .Where(x => !userId.HasValue || x.UserId == userId.Value)
                .Select(x => new
                {
                    x.Id,
                    x.UserId,
                    Username = x.User.Username,
                    FullName = ((x.User.FirstName ?? string.Empty) + " " + (x.User.LastName ?? string.Empty)).Trim(),
                    x.ReservationId,
                    x.WalletId,
                    x.Amount,
                    x.Status,
                    x.Created
                })
                .OrderByDescending(x => x.Created)
                .ToList();

            var completedPayments = payments.Where(x => x.Status == Database.PaymentStatus.Completed).ToList();
            var refundedPayments = payments.Where(x => x.Status == Database.PaymentStatus.Refunded).ToList();
            var pendingPayments = payments.Where(x => x.Status == Database.PaymentStatus.Pending).ToList();

            var grossRevenue = completedPayments.Sum(x => x.Amount);
            var totalRefunds = refundedPayments.Sum(x => x.Amount);
            var netRevenue = grossRevenue - totalRefunds;

            var userBreakdown = completedPayments
                .GroupBy(x => new
                {
                    x.UserId,
                    DisplayName = string.IsNullOrWhiteSpace(x.FullName) ? x.Username : x.FullName
                })
                .Select(x => new
                {
                    x.Key.UserId,
                    x.Key.DisplayName,
                    PaymentCount = x.Count(),
                    TotalAmount = x.Sum(y => y.Amount)
                })
                .OrderByDescending(x => x.TotalAmount)
                .ThenByDescending(x => x.PaymentCount)
                .Take(userId.HasValue ? 1 : 10)
                .ToList();

            QuestPDF.Settings.License = LicenseType.Community;

            return Document.Create(container =>
            {
                container.Page(page =>
                {
                    page.Margin(30);
                    page.Size(PageSizes.A4);

                    page.Header().Column(column =>
                    {
                        column.Item().Text("Parkify finansijski izvještaj")
                            .FontSize(20)
                            .SemiBold();
                        column.Item().Text($"Period: {start:dd.MM.yyyy HH:mm} - {end:dd.MM.yyyy HH:mm}")
                            .FontSize(10)
                            .FontColor(Colors.Grey.Darken2);
                    });

                    page.Content().Column(column =>
                    {
                        column.Spacing(12);

                        column.Item().Row(row =>
                        {
                            row.RelativeItem().Element(block => SummaryCard(block, "Ukupno uplata", payments.Count.ToString()));
                            row.RelativeItem().Element(block => SummaryCard(block, "Bruto prihod", $"{grossRevenue:F2} KM"));
                            row.RelativeItem().Element(block => SummaryCard(block, "Refundacije", $"{totalRefunds:F2} KM"));
                            row.RelativeItem().Element(block => SummaryCard(block, "Neto prihod", $"{netRevenue:F2} KM"));
                        });

                        column.Item().Row(row =>
                        {
                            row.RelativeItem().Element(block => SummaryCard(block, "Rezervacijska", completedPayments.Count(x => x.ReservationId.HasValue).ToString()));
                            row.RelativeItem().Element(block => SummaryCard(block, "Novčanik", completedPayments.Count(x => x.WalletId.HasValue).ToString()));
                            row.RelativeItem().Element(block => SummaryCard(block, "Na čekanju", pendingPayments.Count.ToString()));
                            row.RelativeItem().Element(block => SummaryCard(block, userId.HasValue ? "Korisnik" : "Refundirane", userId.HasValue ? userDisplayName! : refundedPayments.Count.ToString()));
                        });

                        column.Item().Text(userId.HasValue ? "Finansijski pregled korisnika" : "Promet po korisniku").FontSize(14).SemiBold();
                        column.Item().Table(table =>
                        {
                            table.ColumnsDefinition(columns =>
                            {
                                columns.RelativeColumn(3);
                                columns.RelativeColumn(1);
                                columns.RelativeColumn(1);
                            });

                            table.Header(header =>
                            {
                                header.Cell().Element(TableHeader).Text("Korisnik");
                                header.Cell().Element(TableHeader).AlignRight().Text("Uplate");
                                header.Cell().Element(TableHeader).AlignRight().Text("Ukupno");
                            });

                            if (userBreakdown.Any())
                            {
                                foreach (var user in userBreakdown)
                                {
                                    table.Cell().Element(TableCell).Text($"{user.DisplayName} (ID: {user.UserId})");
                                    table.Cell().Element(TableCell).AlignRight().Text(user.PaymentCount.ToString());
                                    table.Cell().Element(TableCell).AlignRight().Text($"{user.TotalAmount:F2} KM");
                                }
                            }
                            else
                            {
                                table.Cell().ColumnSpan(3).Element(TableCell).Text("Nema evidentiranih uplata za odabrani period.");
                            }
                        });

                        column.Item().Text("Posljednje transakcije").FontSize(14).SemiBold();
                        column.Item().Table(table =>
                        {
                            table.ColumnsDefinition(columns =>
                            {
                                columns.RelativeColumn(1);
                                columns.RelativeColumn(1);
                                columns.RelativeColumn(2);
                                columns.RelativeColumn(1);
                                columns.RelativeColumn(2);
                            });

                            table.Header(header =>
                            {
                                header.Cell().Element(TableHeader).Text("ID");
                                header.Cell().Element(TableHeader).Text("Korisnik");
                                header.Cell().Element(TableHeader).Text("Tip");
                                header.Cell().Element(TableHeader).AlignRight().Text("Iznos");
                                header.Cell().Element(TableHeader).Text("Status");
                            });

                            foreach (var payment in payments.Take(15))
                            {
                                table.Cell().Element(TableCell).Text(payment.Id.ToString());
                                table.Cell().Element(TableCell).Text(string.IsNullOrWhiteSpace(payment.FullName) ? $"{payment.Username} ({payment.UserId})" : $"{payment.FullName} ({payment.UserId})");
                                table.Cell().Element(TableCell).Text(payment.ReservationId.HasValue ? "Rezervacija" : "Novčanik");
                                table.Cell().Element(TableCell).AlignRight().Text($"{payment.Amount:F2} KM");
                                table.Cell().Element(TableCell).Text(payment.Status.ToString());
                            }

                            if (!payments.Any())
                            {
                                table.Cell().ColumnSpan(5).Element(TableCell).Text("Nema transakcija za odabrani period.");
                            }
                        });
                    });

                    page.Footer().AlignCenter().Text($"Generisano: {DateTime.UtcNow:dd.MM.yyyy HH:mm} UTC").FontSize(9);
                });
            }).GeneratePdf();
        }

        public override void BeforeInsert(ReservationInsertRequest request, Database.Reservation entity)
        {
            if (entity.ReservationEnd <= entity.ReservationStart)
                throw new UserException("Vrijeme završetka mora biti poslije vremena početka rezervacije.");

            var parkingZone = Context.ParkingZones.Find(entity.ParkingZoneId);
            if (parkingZone == null)
                throw new UserException("Parking zona nije pronađena.");

            if (parkingZone.AvailableSpots <= 0)
            {
                _ = _publisher.PublishNotificationAsync(new parkify.RabbitMQ.Models.NotificationMessage
                {
                    UserId = entity.UserId,
                    Title = "Parking zona je puna",
                    Message = $"Zona {parkingZone.Name} trenutno nema slobodnih mjesta.",
                    Type = (int)Database.NotificationType.ParkingFull,
                    Channel = parkify.RabbitMQ.Models.NotificationChannel.Both,
                    ParkingZoneId = entity.ParkingZoneId
                });
                throw new UserException("Parking zona je puna.");
            }

            var parkingSpot = Context.ParkingSpots.FirstOrDefault(ps => ps.Id == entity.ParkingSpotId);
            if (parkingSpot == null)
                throw new UserException("Parking mjesto nije pronađeno.");

            if (parkingSpot.ParkingZoneId != entity.ParkingZoneId)
                throw new UserException("Odabrano parking mjesto ne pripada traženoj zoni.");

            var hasOverlap = Context.Reservations.Any(r =>
                r.ParkingSpotId == entity.ParkingSpotId &&
                (r.Status == Database.ReservationStatus.Confirmed || r.Status == Database.ReservationStatus.Active) &&
                entity.ReservationStart < r.ReservationEnd &&
                r.ReservationStart < entity.ReservationEnd);

            if (hasOverlap)
                throw new UserException("Odabrano parking mjesto već ima aktivnu ili potvrđenu rezervaciju u traženom terminu.");

            if (!parkingSpot.IsActive)
                throw new UserException("Odabrano parking mjesto nije aktivno.");

            if (!parkingSpot.IsAvailable)
            {
                _ = _publisher.PublishNotificationAsync(new parkify.RabbitMQ.Models.NotificationMessage
                {
                    UserId = entity.UserId,
                    Title = "Nema slobodnih mjesta",
                    Message = $"Parking mjesto {parkingSpot.SpotCode} trenutno nije dostupno.",
                    Type = (int)Database.NotificationType.AvailabilityAlert,
                    Channel = parkify.RabbitMQ.Models.NotificationChannel.Both,
                    ParkingZoneId = entity.ParkingZoneId
                });
                throw new UserException("Odabrano parking mjesto trenutno nije raspoloživo.");
            }

            if (request.RequiresDisabledSpot && parkingSpot.Type != Database.ParkingSpotType.Disabled)
                throw new UserException("Za ovu rezervaciju morate odabrati invalidsko parking mjesto.");

            entity.DurationInHours = (int)Math.Ceiling((entity.ReservationEnd - entity.ReservationStart).TotalHours);
            entity.CalculatedPrice = CalculateReservationPrice(parkingZone, entity.ReservationStart, entity.ReservationEnd);


            var wallet = Context.Wallets.FirstOrDefault(w => w.UserId == entity.UserId);

            if (wallet != null && wallet.Balance > 0)
            {
                var amountFromWallet = Math.Min(wallet.Balance, entity.CalculatedPrice);

                wallet.Balance -= amountFromWallet;
                wallet.Modified = DateTime.UtcNow;
                Context.Wallets.Update(wallet);

                Context.WalletTransactions.Add(new Database.WalletTransaction
                {
                    WalletId = wallet.Id,
                    Amount = -amountFromWallet,
                    Type = Database.WalletTransactionType.Reservation,
                    Created = DateTime.UtcNow
                });

                entity.WalletAmountUsed = amountFromWallet;
                entity.FinalPrice = entity.CalculatedPrice - amountFromWallet;
            }
            else
            {
                entity.WalletAmountUsed = 0;
                entity.FinalPrice = entity.CalculatedPrice;
            }

            entity.PaymentAmountPaid = 0;
            var nowUtc = DateTime.UtcNow;
            var autoConfirmThreshold = nowUtc.AddMinutes(10);

            if (entity.FinalPrice == 0)
            {
                entity.Status = entity.ReservationStart <= autoConfirmThreshold
                    ? Database.ReservationStatus.Confirmed
                    : Database.ReservationStatus.Pending;

                if (parkingZone.AvailableSpots > 0)
                {
                    parkingZone.AvailableSpots -= 1;
                }

                if (parkingSpot != null)
                {
                    parkingSpot.IsAvailable = false;
                    parkingSpot.Modified = DateTime.UtcNow;
                }
            }

            entity.ReservationCode = GenerateReservationCode(request);

            base.BeforeInsert(request, entity);
        }

        public override void AfterInsert(Database.Reservation entity, ReservationInsertRequest request)
        {
            if (entity.Status == Database.ReservationStatus.Pending ||
                entity.Status == Database.ReservationStatus.Confirmed)
            {
                _ = _publisher.PublishNotificationAsync(new parkify.RabbitMQ.Models.NotificationMessage
                {
                    UserId = entity.UserId,
                    Title = entity.Status == Database.ReservationStatus.Confirmed
                        ? "Rezervacija potvrđena"
                        : "Rezervacija kreirana",
                    Message = entity.Status == Database.ReservationStatus.Confirmed
                        ? $"Vaša rezervacija je odmah potvrđena. Kod rezervacije: {entity.ReservationCode}"
                        : $"Vaša rezervacija je uspješno kreirana. Kod rezervacije: {entity.ReservationCode}",
                    Type = (int)Database.NotificationType.ReservationConfirmed,
                    Channel = parkify.RabbitMQ.Models.NotificationChannel.Both,
                    ReservationId = entity.Id,
                    ParkingZoneId = entity.ParkingZoneId
                });
            }

            base.AfterInsert(entity, request);
        }

        public override void BeforeUpdate(ReservationUpdateRequest request, Database.Reservation entity)
        {
            var previousStatus = Context.Reservations
                .AsNoTracking()
                .Where(r => r.Id == entity.Id)
                .Select(r => r.Status)
                .FirstOrDefault();

            if (request.Status.HasValue &&
                request.Status.Value == (int)Database.ReservationStatus.Confirmed)
            {
                if (previousStatus == Database.ReservationStatus.Confirmed)
                {
                    base.BeforeUpdate(request, entity);
                    return;
                }

                if (previousStatus != Database.ReservationStatus.Pending)
                    throw new UserException("Potvrda je dozvoljena samo za rezervacije u statusu Pending.");

                entity.Status = Database.ReservationStatus.Confirmed;
                entity.Modified = DateTime.UtcNow;

                _ = _publisher.PublishNotificationAsync(new parkify.RabbitMQ.Models.NotificationMessage
                {
                    UserId = entity.UserId,
                    Title = "Rezervacija potvrđena",
                    Message = $"Rezervacija {entity.ReservationCode} je potvrđena.",
                    Type = (int)Database.NotificationType.ReservationConfirmed,
                    Channel = parkify.RabbitMQ.Models.NotificationChannel.Both,
                    ReservationId = entity.Id,
                    ParkingZoneId = entity.ParkingZoneId
                });
            }

            if (request.Status.HasValue &&
                request.Status.Value == (int)Database.ReservationStatus.Completed)
            {
                if (previousStatus == Database.ReservationStatus.Completed)
                {
                    base.BeforeUpdate(request, entity);
                    return;
                }

                ReleaseSpotForReservation(entity);
                entity.Status = Database.ReservationStatus.Completed;
                entity.Modified = DateTime.UtcNow;
            }

            if (request.Status.HasValue &&
                request.Status.Value == (int)Database.ReservationStatus.NoShow)
            {
                if (previousStatus == Database.ReservationStatus.NoShow)
                {
                    base.BeforeUpdate(request, entity);
                    return;
                }

                ReleaseSpotForReservation(entity);
                entity.Status = Database.ReservationStatus.NoShow;
                entity.Modified = DateTime.UtcNow;
            }

            if (request.Status.HasValue &&
                request.Status.Value == (int)Database.ReservationStatus.Cancelled)
            {
                if (previousStatus == Database.ReservationStatus.Cancelled)
                {
                    base.BeforeUpdate(request, entity);
                    return;
                }

                if (previousStatus != Database.ReservationStatus.Pending &&
                    previousStatus != Database.ReservationStatus.Confirmed &&
                    previousStatus != Database.ReservationStatus.Active)
                    throw new UserException("Otkazivanje je dozvoljeno samo za rezervacije u statusu Pending, Confirmed ili Active.");

                var refundAmount = entity.WalletAmountUsed + entity.PaymentAmountPaid;

                if (refundAmount > 0)
                {
                    var wallet = Context.Wallets.FirstOrDefault(w => w.UserId == entity.UserId);
                    if (wallet != null)
                    {
                        wallet.Balance += refundAmount;
                        wallet.Modified = DateTime.UtcNow;
                        Context.Wallets.Update(wallet);

                        Context.WalletTransactions.Add(new Database.WalletTransaction
                        {
                            WalletId = wallet.Id,
                            Amount = refundAmount,
                            Type = Database.WalletTransactionType.Cancellation,
                            Created = DateTime.UtcNow
                        });
                    }
                }

                ReleaseSpotForReservation(entity);

                entity.Status = Database.ReservationStatus.Cancelled;
                _ = _publisher.PublishNotificationAsync(new parkify.RabbitMQ.Models.NotificationMessage
                {
                    UserId = entity.UserId,
                    Title = "Rezervacija otkazana",
                    Message = $"Vaša rezervacija je uspješno otkazana. Iznos od {refundAmount:F2} KM je vraćen na vaš novčanik.",
                    Type = (int)Database.NotificationType.ReservationCancelled,
                    Channel = parkify.RabbitMQ.Models.NotificationChannel.Both,
                    ReservationId = entity.Id,
                    ParkingZoneId = entity.ParkingZoneId
                });
            }

            if (request.IsCheckedIn.HasValue && request.IsCheckedIn.Value)
            {
                if (DateTime.UtcNow < entity.ReservationStart)
                    throw new UserException("Check-in prije početka rezervacije.");

                entity.IsCheckedIn = true;
                entity.CheckInTime = request.CheckInTime ?? DateTime.UtcNow;
                entity.Status = Database.ReservationStatus.Active;
            }

            if (request.IsCheckedOut.HasValue && request.IsCheckedOut.Value)
            {
                entity.IsCheckedOut = true;
                entity.CheckOutTime = request.CheckOutTime ?? DateTime.UtcNow;
                entity.Status = Database.ReservationStatus.Completed;

                if (entity.CheckOutTime > entity.ReservationEnd)
                {
                    var extraHours = (int)Math.Ceiling(
                        (entity.CheckOutTime.Value - entity.ReservationEnd).TotalHours);

                    if (extraHours > 0)
                    {
                        var parkingZone = Context.ParkingZones.Find(entity.ParkingZoneId);
                        if (parkingZone != null)
                        {
                            var extraCost = extraHours * parkingZone.PricePerHour;

                            var wallet = Context.Wallets.FirstOrDefault(
                                w => w.UserId == entity.UserId);

                            if (wallet != null)
                            {
                                wallet.Balance -= extraCost;
                                wallet.Modified = DateTime.UtcNow;
                                Context.Wallets.Update(wallet);

                                Context.WalletTransactions.Add(new Database.WalletTransaction
                                {
                                    WalletId = wallet.Id,
                                    Amount = -extraCost,
                                    Type = Database.WalletTransactionType.Extra,
                                    Created = DateTime.UtcNow
                                });

                                entity.FinalPrice += extraCost;
                            }
                        }
                    }
                }

                ReleaseSpotForReservation(entity);
            }

            base.BeforeUpdate(request, entity);
        }

        private void ReleaseSpotForReservation(Database.Reservation reservation)
        {
            var parkingSpot = Context.ParkingSpots.Find(reservation.ParkingSpotId);
            if (parkingSpot == null)
            {
                return;
            }

            if (parkingSpot.IsAvailable)
            {
                return;
            }

            parkingSpot.IsAvailable = true;
            parkingSpot.Modified = DateTime.UtcNow;

            var parkingZone = Context.ParkingZones.Find(reservation.ParkingZoneId);
            if (parkingZone != null)
            {
                parkingZone.AvailableSpots += 1;
            }
        }

        private string GenerateReservationCode(ReservationInsertRequest request)
        {
            var dateTimePart = request.ReservationStart.ToString("yyMMddHHmm");
            var random = Guid.NewGuid().ToString("N").Substring(0, 6).ToUpper();
            return $"U{request.UserId}-Z{request.ParkingZoneId}-{dateTimePart}-{random}";
        }

        private static decimal CalculateReservationPrice(
            Database.ParkingZone parkingZone,
            DateTime reservationStart,
            DateTime reservationEnd)
        {
            var totalHours = (decimal)(reservationEnd - reservationStart).TotalHours;
            var fullDays = (int)Math.Floor(totalHours / 24m);
            var remainingHours = (int)Math.Ceiling(totalHours - (fullDays * 24m));

            return (fullDays * parkingZone.DailyRate) + (remainingHours * parkingZone.PricePerHour);
        }

        private static void SummaryCard(IContainer container, string title, string value)
        {
            container
                .Padding(10)
                .Background(Colors.Grey.Lighten4)
                .Border(1)
                .BorderColor(Colors.Grey.Lighten2)
                .Column(column =>
                {
                    column.Item().Text(title).FontSize(10).FontColor(Colors.Grey.Darken2);
                    column.Item().Text(value).FontSize(14).SemiBold();
                });
        }

        private static IContainer TableHeader(IContainer container)
        {
            return container
                .PaddingVertical(6)
                .PaddingHorizontal(4)
                .Background(Colors.Grey.Lighten3)
                .BorderBottom(1)
                .BorderColor(Colors.Grey.Lighten2);
        }

        private static IContainer TableCell(IContainer container)
        {
            return container
                .PaddingVertical(4)
                .PaddingHorizontal(4)
                .BorderBottom(1)
                .BorderColor(Colors.Grey.Lighten3);
        }
    }
}