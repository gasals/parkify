using MapsterMapper;
using parkify.Model.Models;
using parkify.Model.Requests;
using parkify.Model.SearchObject;
using parkify.Service.Interfaces;

namespace parkify.Service.Services
{
    public class PreferenceService 
        : BaseCRUDService<Preference, PreferenceSearch, Database.Preference, PreferenceInsertRequest, PreferenceUpdateRequest>,
          IPreferenceService
    {
        public PreferenceService(Database.ParkifyContext context, IMapper mapper)
            : base(context, mapper)
        {
        }

        public override IQueryable<Database.Preference> AddFilter(PreferenceSearch search, IQueryable<Database.Preference> query)
        {
            query = base.AddFilter(search, query);

            if (search?.UserId.HasValue == true)
            {
                query = query.Where(x => x.UserId == search.UserId);
            }

            if (!string.IsNullOrWhiteSpace(search?.PreferredCity))
            {
                query = query.Where(x => x.PreferredCity.Contains(search.PreferredCity));
            }

            return query;
        }
    }
}
