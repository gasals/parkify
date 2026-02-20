using MapsterMapper;
using parkify.Model.Models;
using parkify.Model.Requests;
using parkify.Model.SearchObject;
using parkify.Service.Interfaces;

namespace parkify.Service.Services
{
    public class CityService
        : BaseCRUDService<City, CitySearch, Database.City, CityInsertRequest, CityUpdateRequest>,
          ICityService
    {
        public CityService(Database.ParkifyContext context, IMapper mapper)
            : base(context, mapper)
        {
        }

        public override IQueryable<Database.City> AddFilter(CitySearch search, IQueryable<Database.City> query)
        {
            query = base.AddFilter(search, query);
            
            if (!string.IsNullOrEmpty(search?.Name))
            {
                query = query.Where(x => x.Name.Contains(search.Name));
            }
            
            return query;
        }
    }
}
