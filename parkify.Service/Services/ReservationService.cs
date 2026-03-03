using MapsterMapper;
using parkify.Model.Exceptions;
using parkify.Model.Models;
using parkify.Model.Requests;
using parkify.Model.SearchObject;
using parkify.RabbitMQ;
using parkify.Service.Interfaces;

namespace parkify.Service.Services
{
    public class ReservationService
        : BaseCRUDService<Reservation, ReservationSearch, Database.Reservation, ReservationInsertRequest, ReservationUpdateRequest>,
          IReservationService
    {
        private readonly IParkingZoneService _parkingZoneService;
        private readonly IParkingSpotService _parkingSpotService;
        private readonly IMessagePublisher _publisher;

        public ReservationService(
            Database.ParkifyContext context,
            IMapper mapper,
            IParkingZoneService parkingZoneService,
            IParkingSpotService parkingSpotService,
            IMessagePublisher publisher)
            : base(context, mapper)
        {
            _parkingZoneService = parkingZoneService;
            _parkingSpotService = parkingSpotService;
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

        public override void BeforeInsert(ReservationInsertRequest request, Database.Reservation entity)
        {
            entity.DurationInHours = (int)Math.Ceiling((entity.ReservationEnd - entity.ReservationStart).TotalHours);

            var parkingZone = _parkingZoneService.GetById(entity.ParkingZoneId);
            if (parkingZone == null)
                throw new Exception("Parking zona nije pronađena.");

            entity.CalculatedPrice = entity.DurationInHours == 24 ? parkingZone.DailyRate : parkingZone.PricePerHour * entity.DurationInHours;

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

                entity.FinalPrice = entity.CalculatedPrice - amountFromWallet;
            }
            else
            {
                entity.FinalPrice = entity.CalculatedPrice;
            }

            if (entity.FinalPrice == 0)
            {
                entity.Status = Database.ReservationStatus.Confirmed;
                _parkingZoneService.Update(
                    parkingZone.Id,
                    new ParkingZoneUpdateRequest { AvailableSpots = parkingZone.AvailableSpots - 1 });
                _parkingSpotService.SetAvailable(entity.ParkingSpotId, false);
            }

            entity.ReservationCode = GenerateReservationCode(request);

            if (entity.Status == Database.ReservationStatus.Confirmed)
            {
                _publisher.PublishNotification(new parkify.RabbitMQ.Models.NotificationMessage
                {
                    UserId = entity.UserId,
                    Title = "Rezervacija potvrđena",
                    Message = $"Vaša rezervacija je uspješno kreirana i potvrđena. Kod rezervacije: {entity.ReservationCode}",
                    Type = (int)Database.NotificationType.ReservationConfirmed,
                    Channel = parkify.RabbitMQ.Models.NotificationChannel.Both,
                    ReservationId = entity.Id
                });
            }

            base.BeforeInsert(request, entity);
        }

        public override void BeforeUpdate(ReservationUpdateRequest request, Database.Reservation entity)
        {
            if (request.Status.HasValue &&
                request.Status.Value == (int)Database.ReservationStatus.Cancelled)
            {
                if (entity.CalculatedPrice > 0)
                {
                    var wallet = Context.Wallets.FirstOrDefault(w => w.UserId == entity.UserId);
                    if (wallet != null)
                    {
                        wallet.Balance += entity.CalculatedPrice;
                        wallet.Modified = DateTime.UtcNow;
                        Context.Wallets.Update(wallet);

                        Context.WalletTransactions.Add(new Database.WalletTransaction
                        {
                            WalletId = wallet.Id,
                            Amount = entity.CalculatedPrice,
                            Type = Database.WalletTransactionType.Cancellation,
                            Created = DateTime.UtcNow
                        });
                    }
                }

                var zoneForCancel = _parkingZoneService.GetById(entity.ParkingZoneId);
                if (zoneForCancel != null)
                {
                    _parkingZoneService.Update(
                        zoneForCancel.Id,
                        new ParkingZoneUpdateRequest
                        {
                            AvailableSpots = zoneForCancel.AvailableSpots + 1
                        });
                }

                _parkingSpotService.SetAvailable(entity.ParkingSpotId, true);
                entity.Status = Database.ReservationStatus.Cancelled;
                _publisher.PublishNotification(new parkify.RabbitMQ.Models.NotificationMessage
                {
                    UserId = entity.UserId,
                    Title = "Rezervacija otkazana",
                    Message = $"Vaša rezervacija je uspješno otkazana. Iznos od {entity.CalculatedPrice:F2} KM je vraćen na vaš novčanik.",
                    Type = (int)Database.NotificationType.ReservationCancelled,
                    Channel = parkify.RabbitMQ.Models.NotificationChannel.Both,
                    ReservationId = entity.Id
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
                        var parkingZone = _parkingZoneService.GetById(entity.ParkingZoneId);
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
            }

            Context.SaveChanges();
            base.BeforeUpdate(request, entity);
        }

        private string GenerateReservationCode(ReservationInsertRequest request)
        {
            var dateTimePart = request.ReservationStart.ToString("yyMMddHHmm");
            var random = Guid.NewGuid().ToString("N").Substring(0, 6).ToUpper();
            return $"U{request.UserId}-Z{request.ParkingZoneId}-{dateTimePart}-{random}";
        }
    }
}