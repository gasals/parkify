using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using parkify.Model.Models;
using parkify.Model.Requests;
using parkify.Model.SearchObject;
using parkify.Service.Interfaces;

namespace parkify.Service.Services
{
    public class ParkingZoneService
        : BaseCRUDService<ParkingZone, ParkingZoneSearch, Database.ParkingZone, ParkingZoneInsertRequest, ParkingZoneUpdateRequest>,
          IParkingZoneService
    {
        public ParkingZoneService(Database.ParkifyContext context, IMapper mapper)
            : base(context, mapper)
        {
        }

        public override IQueryable<Database.ParkingZone> AddFilter(ParkingZoneSearch search, IQueryable<Database.ParkingZone> query)
        {
            query = base.AddFilter(search, query);

            if (!string.IsNullOrWhiteSpace(search?.Name))
            {
                query = query.Where(x => x.Name.Contains(search.Name));
            }

            if (!string.IsNullOrWhiteSpace(search?.City))
            {
                query = query.Where(x => x.City == search.City);
            }

            if (search?.IncludeSpots == true)
            {
                query = query.Include(x => x.Spots);
            }

            return query;
        }
    }
}