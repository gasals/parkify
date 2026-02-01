using parkify.Model.Helpers;
using parkify.Model.SearchObject;

namespace parkify.Service.Interfaces
{
    public interface IService<TModel, TSearch> where TSearch : BaseSearchObject
    {
        public PagedResult<TModel> GetPaged(TSearch search);

        public TModel GetById(int id);
    }
}
