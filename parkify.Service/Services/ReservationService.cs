using MapsterMapper;
using parkify.Model.Models;
using parkify.Model.Requests;
using parkify.Model.SearchObject;
using parkify.Service.Interfaces;
using Microsoft.EntityFrameworkCore; // Dodano

namespace parkify.Service.Services
{
    public class ReservationService
        : BaseCRUDService<Reservation, ReservationSearch, Database.Reservation, ReservationInsertRequest, ReservationUpdateRequest>,
          IReservationService
    {
        private readonly IParkingZoneService _parkingZoneService;
        private readonly IParkingSpotService _parkingSpotService;

        public ReservationService(Database.ParkifyContext context, IMapper mapper, IParkingZoneService parkingZoneService, IParkingSpotService parkingSpotService)
            : base(context, mapper)
        {
            _parkingZoneService = parkingZoneService;
            _parkingSpotService = parkingSpotService;
        }

        public override IQueryable<Database.Reservation> AddFilter(ReservationSearch search, IQueryable<Database.Reservation> query)
        {
            query = base.AddFilter(search, query);

            if (search?.UserId.HasValue == true)
            {
                query = query.Where(x => x.UserId == search.UserId);
            }

            if (search?.ParkingZoneId.HasValue == true)
            {
                query = query.Where(x => x.ParkingZoneId == search.ParkingZoneId);
            }

            if (search?.Status.HasValue == true)
            {
                query = query.Where(x => (int)x.Status == search.Status);
            }

            query = query.OrderByDescending(x => x.Created);

            return query;
        }

        public override void BeforeInsert(ReservationInsertRequest request, Database.Reservation entity)
        {
            entity.DurationInHours = (int)Math.Ceiling((entity.ReservationEnd - entity.ReservationStart).TotalHours);
            var parkingZone = _parkingZoneService.GetById(entity.ParkingZoneId);

            if (parkingZone != null)
            {
                var pricePerHour = parkingZone.PricePerHour;
                entity.CalculatedPrice = pricePerHour * entity.DurationInHours;

                var wallet = Context.Wallets.FirstOrDefault(w => w.UserId == entity.UserId);

                if (wallet != null && wallet.Balance > 0)
                {
                    var amountFromWallet = Math.Min(wallet.Balance, entity.CalculatedPrice);

                    wallet.Balance -= amountFromWallet;
                    wallet.Modified = DateTime.UtcNow;
                    Context.Wallets.Update(wallet);

                    var transaction = new Database.WalletTransaction
                    {
                        WalletId = wallet.Id,
                        Amount = -amountFromWallet,
                        Type = Database.WalletTransactionType.Reservation,
                        Created = DateTime.UtcNow
                    };
                    Context.WalletTransactions.Add(transaction);

                    entity.FinalPrice = entity.CalculatedPrice - amountFromWallet;

                    if(entity.FinalPrice == 0)
                    {
                        entity.Status = Database.ReservationStatus.Completed;
                        ParkingZoneUpdateRequest updateRequest = new ParkingZoneUpdateRequest { AvailableSpots = parkingZone.AvailableSpots - 1 };
                        _parkingZoneService.Update(parkingZone.Id, updateRequest);
                        _parkingSpotService.SetAvailable(entity.ParkingSpotId, false);
                    }
                }
                else
                {
                    entity.FinalPrice = entity.CalculatedPrice;
                }
            }
            
            entity.ReservationCode = GenerateReservationCode(request);

            base.BeforeInsert(request, entity);
        }

        public override void BeforeUpdate(ReservationUpdateRequest request, Database.Reservation entity)
        {
            if (request.IsCheckedIn.HasValue && request.IsCheckedIn.Value)
            {
                entity.IsCheckedIn = true;
                entity.CheckInTime = request.CheckInTime ?? DateTime.UtcNow;
                entity.Status = Database.ReservationStatus.Active;
            }

            if (request.IsCheckedOut.HasValue && request.IsCheckedOut.Value)
            {
                entity.IsCheckedOut = true;
                entity.CheckOutTime = request.CheckOutTime ?? DateTime.UtcNow;
                entity.Status = Database.ReservationStatus.Completed;
            }

            base.BeforeUpdate(request, entity);
        }

        private string GenerateReservationCode(ReservationInsertRequest request)
        {
            var dateTimePart = request.ReservationStart.ToString("yyMMddHHmm");

            return $"U{request.UserId}-" +
                   $"Z{request.ParkingZoneId}-" +
                   $"{dateTimePart}";
        }
    }
}