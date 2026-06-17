using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using parkify.Model.Helpers;
using parkify.Model.SearchObject;
using parkify.Service.Database;
using parkify.Service.Interfaces;

namespace parkify.Service.Services
{
    public abstract class BaseService<TModel, TSearch, TDbEntity> : IService<TModel, TSearch> where TSearch : BaseSearchObject where TDbEntity : class where TModel : class
    {
        public ParkifyContext Context { get; set; }

        public IMapper Mapper { get; set; }
        public BaseService(ParkifyContext dbContext, IMapper mapper)
        {
            Context = dbContext;
            Mapper = mapper;
        }

        public async Task<PagedResult<TModel>> GetPaged(TSearch searchObject)
        {
            List<TModel> result = new List<TModel>();

            searchObject ??= Activator.CreateInstance<TSearch>();
            searchObject.NormalizePaging();

            var query = Context.Set<TDbEntity>().AsQueryable();

            query = AddFilter(searchObject, query);

            int count = await query.CountAsync();

            int skip = searchObject.Page - 1;
            query = query.Skip(skip * searchObject.PageSize).Take(searchObject.PageSize);

            var list = await query.ToListAsync();

            result = Mapper.Map(list, result);

            PagedResult<TModel> paged = new PagedResult<TModel>();

            paged.Results = result;
            paged.Count = count;

            return paged;
        }

        public virtual IQueryable<TDbEntity> AddFilter(TSearch searchObject, IQueryable<TDbEntity> query)
        {
            return query;
        }

        public virtual async Task<TModel?> GetById(int id)
        {
            var entity = await Context.Set<TDbEntity>().FindAsync(id);

            if (entity != null)
            {
                return Mapper.Map<TModel>(entity);
            }
            else
            {
                return null;
            }
        }
    }
}
