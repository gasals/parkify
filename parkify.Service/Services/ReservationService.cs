using MapsterMapper;
using Microsoft.AspNetCore.Http;
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
using System.Security.Claims;

namespace parkify.Service.Services
{
    public class ReservationService
        : BaseCRUDService<Reservation, ReservationSearch, Database.Reservation, ReservationInsertRequest, ReservationUpdateRequest>,
          IReservationService
    {
        private readonly IMessagePublisher _publisher;
        private readonly IHttpContextAccessor _httpContextAccessor;

        public ReservationService(
            Database.ParkifyContext context,
            IMapper mapper,
            IMessagePublisher publisher,
            IHttpContextAccessor httpContextAccessor)
            : base(context, mapper)
        {
            _publisher = publisher;
            _httpContextAccessor = httpContextAccessor;
        }

        private int? GetActorUserIdFromJwt()
        {
            var claimValue = _httpContextAccessor.HttpContext?.User?.FindFirstValue(ClaimTypes.NameIdentifier);
            if (int.TryParse(claimValue, out var actorUserId))
                return actorUserId;

            return null;
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

        public async Task<byte[]> GenerateAdminReportPdf(DateTime? from, DateTime? to)
        {
            var start = from?.ToUniversalTime() ?? DateTime.UtcNow.Date.AddDays(-30);
            var end = to?.ToUniversalTime() ?? DateTime.UtcNow;

            if (end < start)
            {
                throw new UserException("Datum završetka mora biti poslije datuma početka izvještaja.");
            }

            var resolvedReservationSummary = await Context.Reservations
                .AsNoTracking()
                .Where(x => x.Created >= start && x.Created <= end)
                .GroupBy(_ => 1)
                .Select(x => new
                {
                    ReservationCount = x.Count(),
                    ConfirmedCount = x.Count(y => y.Status == Database.ReservationStatus.Confirmed),
                    CancelledCount = x.Count(y => y.Status == Database.ReservationStatus.Cancelled),
                    TotalWalletUsage = x.Sum(y => y.WalletAmountUsed),
                    TotalDirectPayments = x.Sum(y => y.PaymentAmountPaid)
                })
                .FirstOrDefaultAsync();

            var resolvedPaymentSummary = await Context.Payments
                .AsNoTracking()
                .Where(x => x.Created >= start && x.Created <= end)
                .GroupBy(_ => 1)
                .Select(x => new
                {
                    PaymentCount = x.Count(),
                    TotalRevenue = x.Where(y => y.Status == Database.PaymentStatus.Completed).Sum(y => y.Amount),
                    TotalRefunds = x.Where(y => y.Status == Database.PaymentStatus.Refunded).Sum(y => y.Amount)
                })
                .FirstOrDefaultAsync();

            var resolvedTopZones = await Context.Reservations
                .AsNoTracking()
                .Where(x => x.Created >= start && x.Created <= end)
                .GroupBy(x => new { x.ParkingZoneId, ZoneName = x.ParkingZone.Name })
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
                .ToListAsync();

            var reservationCount = resolvedReservationSummary?.ReservationCount ?? 0;
            var confirmedCount = resolvedReservationSummary?.ConfirmedCount ?? 0;
            var cancelledCount = resolvedReservationSummary?.CancelledCount ?? 0;
            var totalWalletUsage = resolvedReservationSummary?.TotalWalletUsage ?? 0m;
            var totalDirectPayments = resolvedReservationSummary?.TotalDirectPayments ?? 0m;

            var paymentCount = resolvedPaymentSummary?.PaymentCount ?? 0;
            var totalRevenue = resolvedPaymentSummary?.TotalRevenue ?? 0m;
            var totalRefunds = resolvedPaymentSummary?.TotalRefunds ?? 0m;

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
                            row.RelativeItem().Element(block => SummaryCard(block, "Rezervacije", reservationCount.ToString()));
                            row.RelativeItem().Element(block => SummaryCard(block, "Plaćanja", paymentCount.ToString()));
                            row.RelativeItem().Element(block => SummaryCard(block, "Prihod", $"{totalRevenue:F2} KM"));
                            row.RelativeItem().Element(block => SummaryCard(block, "Refundacije", $"{totalRefunds:F2} KM"));
                        });

                        column.Item().Row(row =>
                        {
                            row.RelativeItem().Element(block => SummaryCard(block, "Wallet naplata", $"{totalWalletUsage:F2} KM"));
                            row.RelativeItem().Element(block => SummaryCard(block, "Direktna naplata", $"{totalDirectPayments:F2} KM"));
                            row.RelativeItem().Element(block => SummaryCard(block, "Potvrđene", confirmedCount.ToString()));
                            row.RelativeItem().Element(block => SummaryCard(block, "Otkazane", cancelledCount.ToString()));
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

                            if (resolvedTopZones.Any())
                            {
                                foreach (var zone in resolvedTopZones)
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

        public async Task<byte[]> GenerateFinanceReportPdf(DateTime? from, DateTime? to, int? userId = null)
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
                    .FirstOrDefaultAsync()
                : null;

            var resolvedUserDisplayName = userId.HasValue ? await userDisplayName! : null;

            if (userId.HasValue && string.IsNullOrWhiteSpace(resolvedUserDisplayName))
            {
                throw new UserException("Odabrani korisnik nije pronađen.");
            }

            var paymentsQuery = Context.Payments
                .AsNoTracking()
                .Where(x => x.Created >= start && x.Created <= end)
                .Where(x => !userId.HasValue || x.UserId == userId.Value);

            var resolvedPaymentSummary = await paymentsQuery
                .GroupBy(_ => 1)
                .Select(x => new
                {
                    PaymentCount = x.Count(),
                    PendingCount = x.Count(y => y.Status == Database.PaymentStatus.Pending),
                    RefundedCount = x.Count(y => y.Status == Database.PaymentStatus.Refunded),
                    ReservationPaymentsCount = x.Count(y => y.Status == Database.PaymentStatus.Completed && y.ReservationId.HasValue),
                    WalletPaymentsCount = x.Count(y => y.Status == Database.PaymentStatus.Completed && y.WalletId.HasValue),
                    GrossRevenue = x.Where(y => y.Status == Database.PaymentStatus.Completed).Sum(y => y.Amount),
                    TotalRefunds = x.Where(y => y.Status == Database.PaymentStatus.Refunded).Sum(y => y.Amount)
                })
                .FirstOrDefaultAsync();

            var resolvedPayments = await paymentsQuery
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
                .Take(15)
                .ToListAsync();

            var grossRevenue = resolvedPaymentSummary?.GrossRevenue ?? 0m;
            var totalRefunds = resolvedPaymentSummary?.TotalRefunds ?? 0m;
            var netRevenue = grossRevenue - totalRefunds;
            var paymentCount = resolvedPaymentSummary?.PaymentCount ?? 0;
            var pendingCount = resolvedPaymentSummary?.PendingCount ?? 0;
            var refundedCount = resolvedPaymentSummary?.RefundedCount ?? 0;
            var reservationPaymentsCount = resolvedPaymentSummary?.ReservationPaymentsCount ?? 0;
            var walletPaymentsCount = resolvedPaymentSummary?.WalletPaymentsCount ?? 0;

            var userBreakdown = paymentsQuery
                .Where(x => x.Status == Database.PaymentStatus.Completed)
                .GroupBy(x => new
                {
                    x.UserId,
                    DisplayName = string.IsNullOrWhiteSpace(x.User.FirstName) && string.IsNullOrWhiteSpace(x.User.LastName)
                        ? x.User.Username
                        : ((x.User.FirstName ?? string.Empty) + " " + (x.User.LastName ?? string.Empty)).Trim()
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
                .ToListAsync();

            var resolvedUserBreakdown = await userBreakdown;

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
                            row.RelativeItem().Element(block => SummaryCard(block, "Ukupno uplata", paymentCount.ToString()));
                            row.RelativeItem().Element(block => SummaryCard(block, "Bruto prihod", $"{grossRevenue:F2} KM"));
                            row.RelativeItem().Element(block => SummaryCard(block, "Refundacije", $"{totalRefunds:F2} KM"));
                            row.RelativeItem().Element(block => SummaryCard(block, "Neto prihod", $"{netRevenue:F2} KM"));
                        });

                        column.Item().Row(row =>
                        {
                            row.RelativeItem().Element(block => SummaryCard(block, "Rezervacijska", reservationPaymentsCount.ToString()));
                            row.RelativeItem().Element(block => SummaryCard(block, "Novčanik", walletPaymentsCount.ToString()));
                            row.RelativeItem().Element(block => SummaryCard(block, "Na čekanju", pendingCount.ToString()));
                            row.RelativeItem().Element(block => SummaryCard(block, userId.HasValue ? "Korisnik" : "Refundirane", userId.HasValue ? resolvedUserDisplayName! : refundedCount.ToString()));
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

                            if (resolvedUserBreakdown.Any())
                            {
                                foreach (var user in resolvedUserBreakdown)
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

                            foreach (var payment in resolvedPayments.Take(15))
                            {
                                table.Cell().Element(TableCell).Text(payment.Id.ToString());
                                table.Cell().Element(TableCell).Text(string.IsNullOrWhiteSpace(payment.FullName) ? $"{payment.Username} ({payment.UserId})" : $"{payment.FullName} ({payment.UserId})");
                                table.Cell().Element(TableCell).Text(payment.ReservationId.HasValue ? "Rezervacija" : "Novčanik");
                                table.Cell().Element(TableCell).AlignRight().Text($"{payment.Amount:F2} KM");
                                table.Cell().Element(TableCell).Text(payment.Status.ToString());
                            }

                            if (!resolvedPayments.Any())
                            {
                                table.Cell().ColumnSpan(5).Element(TableCell).Text("Nema transakcija za odabrani period.");
                            }
                        });
                    });

                    page.Footer().AlignCenter().Text($"Generisano: {DateTime.UtcNow:dd.MM.yyyy HH:mm} UTC").FontSize(9);
                });
            }).GeneratePdf();
        }

        public override async Task BeforeInsert(ReservationInsertRequest request, Database.Reservation entity)
        {
            entity.ReservationStart = ReservationLifecycleCoordinator.NormalizeToUtc(entity.ReservationStart);
            entity.ReservationEnd = ReservationLifecycleCoordinator.NormalizeToUtc(entity.ReservationEnd);

            if (entity.ReservationEnd <= entity.ReservationStart)
                throw new UserException("Vrijeme završetka mora biti poslije vremena početka rezervacije.");

            var parkingZone = await Context.ParkingZones.FindAsync(entity.ParkingZoneId);
            if (parkingZone == null)
                throw new UserException("Parking zona nije pronađena.");

            var parkingSpot = await Context.ParkingSpots.FirstOrDefaultAsync(ps => ps.Id == entity.ParkingSpotId);
            if (parkingSpot == null)
                throw new UserException("Parking mjesto nije pronađeno.");

            if (parkingSpot.ParkingZoneId != entity.ParkingZoneId)
                throw new UserException("Odabrano parking mjesto ne pripada traženoj zoni.");

            var hasOverlap = await Context.Reservations.AnyAsync(r =>
                r.ParkingSpotId == entity.ParkingSpotId &&
                (r.Status == Database.ReservationStatus.Pending ||
                 r.Status == Database.ReservationStatus.Confirmed ||
                 r.Status == Database.ReservationStatus.Active) &&
                entity.ReservationStart < r.ReservationEnd &&
                r.ReservationStart < entity.ReservationEnd);

            if (hasOverlap)
                throw new UserException("Odabrano parking mjesto već ima aktivnu ili potvrđenu rezervaciju u traženom terminu.");

            var hasUserOverlap = await Context.Reservations.AnyAsync(r =>
                r.UserId == entity.UserId &&
                (r.Status == Database.ReservationStatus.Pending ||
                 r.Status == Database.ReservationStatus.Confirmed ||
                 r.Status == Database.ReservationStatus.Active) &&
                entity.ReservationStart < r.ReservationEnd &&
                r.ReservationStart < entity.ReservationEnd);

            if (hasUserOverlap)
                throw new UserException("Korisnik već ima rezervaciju koja se vremenski preklapa sa odabranim terminom.");

            if (!parkingSpot.IsActive)
                throw new UserException("Odabrano parking mjesto nije aktivno.");

            if (request.RequiresDisabledSpot && parkingSpot.Type != Database.ParkingSpotType.Disabled)
                throw new UserException("Za ovu rezervaciju morate odabrati invalidsko parking mjesto.");

            var normalizedVehiclePlate = (entity.VehicleLicensePlate ?? string.Empty).Trim();
            if (string.IsNullOrWhiteSpace(normalizedVehiclePlate))
                throw new UserException("Registracija vozila je obavezna za kreiranje rezervacije.");

            entity.VehicleLicensePlate = normalizedVehiclePlate;

            var ownsVehicle = await Context.Vehicles
                .AsNoTracking()
                .AnyAsync(v => v.UserId == entity.UserId &&
                               v.LicensePlate.ToUpper() == normalizedVehiclePlate.ToUpper());

            if (!ownsVehicle)
                throw new UserException("Odabrana registracija nije povezana sa korisnikovim vozilom.");

            entity.DurationInHours = (int)Math.Ceiling((entity.ReservationEnd - entity.ReservationStart).TotalHours);
            entity.CalculatedPrice = CalculateReservationPrice(parkingZone, entity.ReservationStart, entity.ReservationEnd);


            var wallet = await Context.Wallets.FirstOrDefaultAsync(w => w.UserId == entity.UserId);

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

                if (entity.Status == Database.ReservationStatus.Confirmed)
                {
                    await ReservationLifecycleCoordinator.ReserveSpotAsync(
                        Context,
                        entity.ParkingZoneId,
                        entity.ParkingSpotId,
                        DateTime.UtcNow);
                }
            }

            entity.ReservationCode = GenerateReservationCode(entity);

            await base.BeforeInsert(request, entity);
        }

        public override async Task AfterInsert(Database.Reservation entity, ReservationInsertRequest request)
        {
            if (entity.Status == Database.ReservationStatus.Pending ||
                entity.Status == Database.ReservationStatus.Confirmed)
            {
                await _publisher.PublishNotificationAsync(new parkify.RabbitMQ.Models.NotificationMessage
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

            await base.AfterInsert(entity, request);
        }

        public override async Task BeforeUpdate(ReservationUpdateRequest request, Database.Reservation entity)
        {
            var previousStatus = Context.Reservations
                .AsNoTracking()
                .Where(r => r.Id == entity.Id)
                .Select(r => r.Status)
                .FirstOrDefaultAsync();

            var resolvedPreviousStatus = await previousStatus;

            var actorUserId = GetActorUserIdFromJwt();

            if (actorUserId.HasValue)
            {
                entity.ModifiedBy = actorUserId.Value;
            }

            if (request.Status.HasValue &&
                request.Status.Value == (int)Database.ReservationStatus.Confirmed)
            {
                if (resolvedPreviousStatus == Database.ReservationStatus.Confirmed)
                {
                    await base.BeforeUpdate(request, entity);
                    return;
                }

                if (resolvedPreviousStatus != Database.ReservationStatus.Pending)
                    throw new UserException("Potvrda je dozvoljena samo za rezervacije u statusu Pending.");

                entity.Status = Database.ReservationStatus.Confirmed;
                entity.Modified = DateTime.UtcNow;
                await ReservationLifecycleCoordinator.ReserveSpotAsync(
                    Context,
                    entity.ParkingZoneId,
                    entity.ParkingSpotId,
                    DateTime.UtcNow);

                await _publisher.PublishNotificationAsync(new parkify.RabbitMQ.Models.NotificationMessage
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
                if (resolvedPreviousStatus == Database.ReservationStatus.Completed)
                {
                    await base.BeforeUpdate(request, entity);
                    return;
                }

                await ReservationLifecycleCoordinator.ReleaseSpotAsync(
                    Context,
                    entity.ParkingZoneId,
                    entity.ParkingSpotId,
                    DateTime.UtcNow);
                entity.Status = Database.ReservationStatus.Completed;
                entity.Modified = DateTime.UtcNow;

                await _publisher.PublishNotificationAsync(new parkify.RabbitMQ.Models.NotificationMessage
                {
                    UserId = entity.UserId,
                    Title = "Rezervacija završena",
                    Message = $"Rezervacija {entity.ReservationCode} je uspješno završena.",
                    Type = (int)Database.NotificationType.ReservationConfirmed,
                    Channel = parkify.RabbitMQ.Models.NotificationChannel.Both,
                    ReservationId = entity.Id,
                    ParkingZoneId = entity.ParkingZoneId
                });
            }

            if (request.Status.HasValue &&
                request.Status.Value == (int)Database.ReservationStatus.NoShow)
            {
                if (resolvedPreviousStatus == Database.ReservationStatus.NoShow)
                {
                    await base.BeforeUpdate(request, entity);
                    return;
                }

                await ReservationLifecycleCoordinator.ReleaseSpotAsync(
                    Context,
                    entity.ParkingZoneId,
                    entity.ParkingSpotId,
                    DateTime.UtcNow);
                entity.Status = Database.ReservationStatus.NoShow;
                entity.Modified = DateTime.UtcNow;

                await _publisher.PublishNotificationAsync(new parkify.RabbitMQ.Models.NotificationMessage
                {
                    UserId = entity.UserId,
                    Title = "Rezervacija oznacena kao no-show",
                    Message = $"Rezervacija {entity.ReservationCode} je oznacena kao no-show.",
                    Type = (int)Database.NotificationType.ReservationCancelled,
                    Channel = parkify.RabbitMQ.Models.NotificationChannel.Both,
                    ReservationId = entity.Id,
                    ParkingZoneId = entity.ParkingZoneId
                });
            }

            if (request.Status.HasValue &&
                request.Status.Value == (int)Database.ReservationStatus.Cancelled)
            {
                if (resolvedPreviousStatus == Database.ReservationStatus.Cancelled)
                {
                    await base.BeforeUpdate(request, entity);
                    return;
                }

                if (resolvedPreviousStatus != Database.ReservationStatus.Pending &&
                    resolvedPreviousStatus != Database.ReservationStatus.Confirmed &&
                    resolvedPreviousStatus != Database.ReservationStatus.Active)
                    throw new UserException("Otkazivanje je dozvoljeno samo za rezervacije u statusu Pending, Confirmed ili Active.");

                var refundAmount = entity.WalletAmountUsed + entity.PaymentAmountPaid;

                if (refundAmount > 0)
                {
                    var wallet = await Context.Wallets.FirstOrDefaultAsync(w => w.UserId == entity.UserId);
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

                await ReservationLifecycleCoordinator.ReleaseSpotAsync(
                    Context,
                    entity.ParkingZoneId,
                    entity.ParkingSpotId,
                    DateTime.UtcNow);

                entity.Status = Database.ReservationStatus.Cancelled;
                await _publisher.PublishNotificationAsync(new parkify.RabbitMQ.Models.NotificationMessage
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
                entity.CheckInTime = request.CheckInTime.HasValue
                    ? ReservationLifecycleCoordinator.NormalizeToUtc(request.CheckInTime.Value)
                    : DateTime.UtcNow;
                entity.CheckInBy = actorUserId;
                entity.Status = Database.ReservationStatus.Active;

                await _publisher.PublishNotificationAsync(new parkify.RabbitMQ.Models.NotificationMessage
                {
                    UserId = entity.UserId,
                    Title = "Check-in evidentiran",
                    Message = $"Vaš check-in za rezervaciju {entity.ReservationCode} je evidentiran.",
                    Type = (int)Database.NotificationType.CheckInReminder,
                    Channel = parkify.RabbitMQ.Models.NotificationChannel.Both,
                    ReservationId = entity.Id,
                    ParkingZoneId = entity.ParkingZoneId
                });
            }

            if (request.IsCheckedOut.HasValue && request.IsCheckedOut.Value)
            {
                entity.IsCheckedOut = true;
                entity.CheckOutTime = request.CheckOutTime.HasValue
                    ? ReservationLifecycleCoordinator.NormalizeToUtc(request.CheckOutTime.Value)
                    : DateTime.UtcNow;
                entity.Status = Database.ReservationStatus.Completed;

                if (entity.CheckOutTime > entity.ReservationEnd)
                {
                    var extraHours = (int)Math.Ceiling(
                        (entity.CheckOutTime.Value - entity.ReservationEnd).TotalHours);

                    if (extraHours > 0)
                    {
                            var parkingZone = await Context.ParkingZones.FindAsync(entity.ParkingZoneId);
                        if (parkingZone != null)
                        {
                            var extraCost = extraHours * parkingZone.PricePerHour;

                                var wallet = await Context.Wallets.FirstOrDefaultAsync(
                                w => w.UserId == entity.UserId);

                            if (wallet != null)
                            {
                                if (wallet.Balance < extraCost)
                                    throw new UserException("Novčanik nema dovoljno sredstava za dodatni trošak kašnjenja. Prvo dopunite novčanik.");

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

                await ReservationLifecycleCoordinator.ReleaseSpotAsync(
                    Context,
                    entity.ParkingZoneId,
                    entity.ParkingSpotId,
                    DateTime.UtcNow);
            }

            await base.BeforeUpdate(request, entity);
        }

        private string GenerateReservationCode(Database.Reservation reservation)
        {
            var dateTimePart = reservation.ReservationStart.ToString("yyMMddHHmm");
            var random = Guid.NewGuid().ToString("N").Substring(0, 6).ToUpper();
            return $"U{reservation.UserId}-Z{reservation.ParkingZoneId}-{dateTimePart}-{random}";
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
