using Mapster;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using parkify.Model.SearchObject;
using parkify.Service.Database;

namespace parkify.Service.Services
{
    public abstract class BaseCRUDService<TModel, TSearch, TDbEntity, TInsert, TUpdate> : BaseService<TModel, TSearch, TDbEntity> where TModel : class where TSearch : BaseSearchObject where TDbEntity : class
    {
        public BaseCRUDService(ParkifyContext dbContext, IMapper mapper) : base(dbContext, mapper)
        {
        }

        public virtual async Task<TModel> Insert(TInsert request)
        {
            await using var transaction = await Context.Database.BeginTransactionAsync();

            TDbEntity entity = Mapper.Map<TDbEntity>(request);

            try
            {
                await BeforeInsert(request, entity);

                if (typeof(TDbEntity).GetProperty("Created") != null)
                {
                    typeof(TDbEntity)?.GetProperty("Created")?.SetValue(entity, DateTime.UtcNow);
                }

                Context.Add(entity);
                await Context.SaveChangesAsync();

                await AfterInsert(entity, request);
                await transaction.CommitAsync();

                return Mapper.Map<TModel>(entity);
            }
            catch
            {
                await transaction.RollbackAsync();
                throw;
            }
        }

        public virtual Task BeforeInsert(TInsert request, TDbEntity entity) => Task.CompletedTask;

        public virtual Task AfterInsert(TDbEntity entity, TInsert request) => Task.CompletedTask;

        public virtual async Task<TModel> Update(int id, TUpdate request)
        {
            await using var transaction = await Context.Database.BeginTransactionAsync();

            var set = Context.Set<TDbEntity>();

            var entity = await set.FindAsync(id);

            try
            {
                Mapper.Config.Default.IgnoreNullValues(true);

                Mapper.Map(request, entity);

                Mapper.Config.Default.IgnoreNullValues(false);

                await BeforeUpdate(request, entity);

                if (typeof(TDbEntity).GetProperty("Modified") != null)
                {
                    typeof(TDbEntity)?.GetProperty("Modified")?.SetValue(entity, DateTime.UtcNow);
                }

                await Context.SaveChangesAsync();
                await transaction.CommitAsync();

                return Mapper.Map<TModel>(entity);
            }
            catch
            {
                Mapper.Config.Default.IgnoreNullValues(false);
                await transaction.RollbackAsync();
                throw;
            }
        }
        public virtual Task BeforeUpdate(TUpdate request, TDbEntity entity) => Task.CompletedTask;

    }
}
