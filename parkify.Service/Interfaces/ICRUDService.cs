using parkify.Model.SearchObject;

namespace parkify.Service.Interfaces
{
    public interface ICRUDService<TModel, TSearch, TInsert, TUpdate> : IService<TModel, TSearch> where TModel : class where TSearch : BaseSearchObject
    {
        TModel Insert(TInsert request);
        TModel Update(int id, TUpdate request);
    }
}
