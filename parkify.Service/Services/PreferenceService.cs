using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using parkify.Model.Exceptions;
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

            if (search?.PreferredCityId.HasValue == true)
            {
                query = query.Where(x => x.PreferredCityId == search.PreferredCityId);
            }

            return query;
        }

        public async Task<Preference> GetOrCreateUserPreference(int userId)
        {
            var search = new PreferenceSearch { UserId = userId };
            var query = AddFilter(search, Context.Set<Database.Preference>().AsQueryable());
            var preference = await query.FirstOrDefaultAsync();

            if (preference == null)
            {
                var newPreference = new PreferenceInsertRequest
                {
                    UserId = userId,
                    PrefersNearby = true,
                    NotifyAboutOffers = true
                };

                var created = await Insert(newPreference);
                return created;
            }

            return Mapper.Map<Preference>(preference);
        }

        public async Task<Preference> UpdateUserPreferences(int userId, PreferenceUpdateRequest request)
        {
            var search = new PreferenceSearch { UserId = userId };
            var query = AddFilter(search, Context.Set<Database.Preference>().AsQueryable());
            var preference = await query.FirstOrDefaultAsync();

            if (preference == null)
            {
                throw new UserException("Korisničke preference nisu pronađene");
            }

            await Update(preference.Id, request);
            return Mapper.Map<Preference>(preference);
        }
    }
}
