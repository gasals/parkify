using MapsterMapper;
using parkify.Model.Exceptions;
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
            var parkingZone = Context.ParkingZones.Find(request.ParkingZoneId);
            if (parkingZone == null)
                throw new UserException("Ne postoji zona sa proslijeđenim ID-em.");

            parkingZone.TotalSpots += 1;
            if (request.Type == (int)ParkingSpotType.Disabled)
            {
                parkingZone.DisabledSpots += 1;
            }

            if (request.IsAvailable)
            {
                parkingZone.AvailableSpots += 1;
            }

            entity.SpotCode = $"Z{request.ParkingZoneId}/{request.RowNumber}-{request.ColumnNumber}";

            base.BeforeInsert(request, entity);
        }

        public ParkingSpot Delete(int id)
        {
            var entity = Context.ParkingSpots.FirstOrDefault(x => x.Id == id);
            if (entity == null)
            {
                throw new UserException("Parking mjesto sa proslijeđenim ID-em ne postoji.");
            }

            var hasReservations = Context.Reservations.Any(x => x.ParkingSpotId == id);
            if (hasReservations)
            {
                throw new UserException("Parking mjesto se ne može obrisati jer ima povezane rezervacije. Deaktivirajte ga umjesto brisanja.");
            }

            var parkingZone = Context.ParkingZones.Find(entity.ParkingZoneId);
            if (parkingZone != null)
            {
                parkingZone.TotalSpots = Math.Max(0, parkingZone.TotalSpots - 1);

                if (entity.Type == Database.ParkingSpotType.Disabled)
                {
                    parkingZone.DisabledSpots = Math.Max(0, parkingZone.DisabledSpots - 1);
                }

                if (entity.IsAvailable)
                {
                    parkingZone.AvailableSpots = Math.Max(0, parkingZone.AvailableSpots - 1);
                }
            }

            Context.ParkingSpots.Remove(entity);
            Context.SaveChanges();

            return Mapper.Map<ParkingSpot>(entity);
        }

        public ParkingSpot SetAvailable(int id, bool isAvailable)
        {
            var entity = Context.ParkingSpots.Find(id);
            if (entity == null)
                throw new UserException("Ne postoji mjesto sa proslijeđenim ID-em.");

            entity.IsAvailable = isAvailable;
            entity.Modified = DateTime.UtcNow;
            Context.SaveChanges();

            return Mapper.Map<ParkingSpot>(entity);
        }
    }
}