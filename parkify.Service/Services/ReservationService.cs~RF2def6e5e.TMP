using MapsterMapper;
using parkify.Model.Models;
using parkify.Model.Requests;
using parkify.Model.SearchObject;
using parkify.Service.Interfaces;

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

            return query;
        }

        public override void BeforeInsert(ReservationInsertRequest request, Database.Reservation entity)
        {

            entity.DurationInHours = (int)Math.Ceiling((entity.ReservationEnd - entity.ReservationStart).TotalHours);

            var parkingZone = _parkingZoneService.GetById(entity.ParkingZoneId);

            if(parkingZone != null)
            {
                var pricePerHour = parkingZone.PricePerHour;
                entity.CalculatedPrice = pricePerHour * entity.DurationInHours;
                entity.FinalPrice = entity.CalculatedPrice;
            }

            entity.ReservationCode = Guid.NewGuid().ToString();

            _parkingSpotService.SetAvailable(entity.ParkingSpotId, false);

            base.BeforeInsert(request, entity);
        }
    }
}
