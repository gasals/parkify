using Microsoft.AspNetCore.Mvc;
using parkify.Model.Models;
using parkify.Model.Requests;
using parkify.Model.SearchObject;
using parkify.Service.Interfaces;

namespace parkify.API.Controllers
{
    public class PreferenceController : BaseCRUDController<Preference, PreferenceSearch, PreferenceInsertRequest, PreferenceUpdateRequest>
    {
        public PreferenceController(IPreferenceService service) : base(service)
        {
        }
    }
}
