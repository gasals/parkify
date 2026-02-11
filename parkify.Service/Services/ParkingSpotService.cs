using MapsterMapper;
using parkify.Model.Models;
using parkify.Model.Requests;
using parkify.Model.SearchObject;
using parkify.Service.Interfaces;

namespace parkify.Service.Services
{
    public class ParkingSpotService
        : BaseCRUDService<ParkingSpot, ParkingSpotSearch, Database.ParkingSpot, ParkingSpotInsertRequest, ParkingSpotUpdateRequest>,
          IParkingSpotService
    {
        public ParkingSpotService(Database.ParkifyContext context, IMapper mapper)
            : base(context, mapper)
        {
        }

        public override IQueryable<Database.ParkingSpot> AddFilter(ParkingSpotSearch search, IQueryable<Database.ParkingSpot> query)
        {
            query = base.AddFilter(search, query);

            if (search?.ParkingZoneId.HasValue == true)
            {
                query = query.Where(x => x.ParkingZoneId == search.ParkingZoneId);
            }

            if (!string.IsNullOrWhiteSpace(search?.SpotCode))
            {
                query = query.Where(x => x.SpotCode.Contains(search.SpotCode));
            }

            if (search?.IsAvailable.HasValue == true)
            {
                query = query.Where(x => x.IsAvailable == search.IsAvailable);
            }

            if (search?.Type.HasValue == true)
            {
                query = query.Where(x => (int)x.Type == search.Type);
            }


            return query;
        }

        public override void BeforeInsert(ParkingSpotInsertRequest request, Database.ParkingSpot entity)
        {
            entity.SpotCode = $"Z{request.ParkingZoneId}/{request.RowNumber}-{request.ColumnNumber}";
            base.BeforeInsert(request, entity);
        }

        public ParkingSpot SetAvailable(int id, bool isAvailable)
        {
            var spot = GetById(id);
            if (spot == null)
                throw new Exception("Ne postoji mjesto sa proslijeđenim ID-em.");

            ParkingSpotUpdateRequest updateRequest = new ParkingSpotUpdateRequest { SpotCode = spot.SpotCode, IsAvailable = isAvailable };

            return Update(id, updateRequest);
        }
    }
}