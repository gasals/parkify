using MapsterMapper;
using parkify.Model.Models;
using parkify.Model.Requests;
using parkify.Model.SearchObject;
using parkify.Service.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace parkify.Service.Services
{
    public class ReservationService
        : BaseCRUDService<Reservation, ReservationSearch, Database.Reservation, ReservationInsertRequest, ReservationUpdateRequest>,
          IReservationService
    {
        private readonly IParkingZoneService _parkingZoneService;
        private readonly IParkingSpotService _parkingSpotService;

        public ReservationService(
            Database.ParkifyContext context,
            IMapper mapper,
            IParkingZoneService parkingZoneService,
            IParkingSpotService parkingSpotService)
            : base(context, mapper)
        {
            _parkingZoneService = parkingZoneService;
            _parkingSpotService = parkingSpotService;
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
            // FE sends times rounded to full hours, so TotalHours is always a whole number.
            // Using (int) cast is safe here; Ceiling kept as safety net.
            entity.DurationInHours = (int)Math.Ceiling(
                (entity.ReservationEnd - entity.ReservationStart).TotalHours);

            var parkingZone = _parkingZoneService.GetById(entity.ParkingZoneId);
            if (parkingZone == null)
                throw new Exception("Parking zona nije pronađena.");

            // --- Price calculation ---
            // Daily option: exactly 24h → use daily flat rate
            // Hourly option: 1–23h → pricePerHour × hours
            entity.CalculatedPrice = entity.DurationInHours == 24
                ? parkingZone.DailyRate
                : parkingZone.PricePerHour * entity.DurationInHours;

            // --- Wallet deduction ---
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

            // If wallet fully covered the reservation, confirm immediately
            if (entity.FinalPrice == 0)
            {
                entity.Status = Database.ReservationStatus.Confirmed;
                _parkingZoneService.Update(
                    parkingZone.Id,
                    new ParkingZoneUpdateRequest { AvailableSpots = parkingZone.AvailableSpots - 1 });
                _parkingSpotService.SetAvailable(entity.ParkingSpotId, false);
            }

            entity.ReservationCode = GenerateReservationCode(request);

            base.BeforeInsert(request, entity);
        }

        public override void BeforeUpdate(ReservationUpdateRequest request, Database.Reservation entity)
        {
            // --- Cancellation ---
            if (request.Status.HasValue &&
                request.Status.Value == (int)Database.ReservationStatus.Cancelled)
            {
                // Refund the full calculated price (wallet covered part or all of it)
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
            }

            // --- Check-in ---
            if (request.IsCheckedIn.HasValue && request.IsCheckedIn.Value)
            {
                if (DateTime.UtcNow < entity.ReservationStart)
                    throw new Exception("Check-in prije početka rezervacije.");

                entity.IsCheckedIn = true;
                entity.CheckInTime = request.CheckInTime ?? DateTime.UtcNow;
                entity.Status = Database.ReservationStatus.Active;
            }

            // --- Check-out ---
            if (request.IsCheckedOut.HasValue && request.IsCheckedOut.Value)
            {
                entity.IsCheckedOut = true;
                entity.CheckOutTime = request.CheckOutTime ?? DateTime.UtcNow;
                entity.Status = Database.ReservationStatus.Completed;

                // Charge extra hours if checked out after reservation end
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
            return $"U{request.UserId}-Z{request.ParkingZoneId}-{dateTimePart}";
        }
    }
}