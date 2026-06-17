using parkify.Model.Helpers;
using parkify.Model.SearchObject;

namespace parkify.Service.Interfaces
{
    public interface IService<TModel, TSearch> where TSearch : BaseSearchObject
    {
        public Task<PagedResult<TModel>> GetPaged(TSearch search);

        public Task<TModel?> GetById(int id);
    }
}
