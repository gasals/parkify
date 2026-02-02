using parkify.Model.Models;
using parkify.Model.Requests;
using parkify.Model.SearchObject;

namespace parkify.Service.Interfaces
{
    public interface IPreferenceService : ICRUDService<Preference, PreferenceSearch, PreferenceInsertRequest, PreferenceUpdateRequest>
    {
    }
}
