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

        public virtual TModel Insert(TInsert request)
        {
            using var transaction = Context.Database.BeginTransaction();

            TDbEntity entity = Mapper.Map<TDbEntity>(request);

            try
            {
                BeforeInsert(request, entity);

                if (typeof(TDbEntity).GetProperty("Created") != null)
                {
                    typeof(TDbEntity)?.GetProperty("Created")?.SetValue(entity, DateTime.UtcNow);
                }

                Context.Add(entity);
                Context.SaveChanges();

                AfterInsert(entity, request);
                transaction.Commit();

                return Mapper.Map<TModel>(entity);
            }
            catch
            {
                transaction.Rollback();
                throw;
            }
        }

        public virtual void BeforeInsert(TInsert request, TDbEntity entity) { }

        public virtual void AfterInsert(TDbEntity entity, TInsert request) { }

        public virtual TModel Update(int id, TUpdate request)
        {
            using var transaction = Context.Database.BeginTransaction();

            var set = Context.Set<TDbEntity>();

            var entity = set.Find(id);

            try
            {
                Mapper.Config.Default.IgnoreNullValues(true);

                Mapper.Map(request, entity);

                Mapper.Config.Default.IgnoreNullValues(false);

                BeforeUpdate(request, entity);

                if (typeof(TDbEntity).GetProperty("Modified") != null)
                {
                    typeof(TDbEntity)?.GetProperty("Modified")?.SetValue(entity, DateTime.UtcNow);
                }

                Context.SaveChanges();
                transaction.Commit();

                return Mapper.Map<TModel>(entity);
            }
            catch
            {
                Mapper.Config.Default.IgnoreNullValues(false);
                transaction.Rollback();
                throw;
            }
        }
        public virtual void BeforeUpdate(TUpdate request, TDbEntity entity) { }

    }
}
