using MapsterMapper;
using parkify.Model.Models;
using parkify.Model.Requests;
using parkify.Model.SearchObject;
using parkify.Service.Interfaces;
using System.Linq;

namespace parkify.Service.Services
{
    public class VehicleService
        : BaseCRUDService<Vehicle, VehicleSearchObject, Database.Vehicle, VehicleInsertRequest, VehicleUpdateRequest>,
          IVehicleService
    {
        public VehicleService(Database.ParkifyContext context, IMapper mapper)
            : base(context, mapper)
        {
        }

        public override IQueryable<Database.Vehicle> AddFilter(VehicleSearchObject search, IQueryable<Database.Vehicle> query)
        {
            query = base.AddFilter(search, query);

            if (search?.UserId.HasValue == true)
            {
                query = query.Where(x => x.UserId == search.UserId);
            }

            if (!string.IsNullOrWhiteSpace(search?.LicensePlate))
            {
                query = query.Where(x => x.LicensePlate.Contains(search.LicensePlate));
            }

            return query;
        }
    }
}