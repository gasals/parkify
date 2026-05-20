using MapsterMapper;
using parkify.Model.Exceptions;
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

        public City Delete(int id)
        {
            var entity = Context.Cities.FirstOrDefault(x => x.Id == id);
            if (entity == null)
            {
                throw new UserException("Grad sa proslijeđenim ID-em ne postoji.");
            }

            var hasDependencies = Context.ParkingZones.Any(x => x.CityId == id)
                || Context.Preferences.Any(x => x.PreferredCityId == id);

            if (hasDependencies)
            {
                throw new UserException("Grad se ne može obrisati jer je povezan sa parking zonama ili korisničkim preferencijama.");
            }

            Context.Cities.Remove(entity);
            Context.SaveChanges();

            return Mapper.Map<City>(entity);
        }
    }
}
