using Microsoft.AspNetCore.Mvc;
using parkify.Model.Models;
using parkify.Model.Requests;
using parkify.Model.SearchObject;
using parkify.Service.Interfaces;

namespace parkify.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class CityController : BaseController<City, CitySearch>
    {

        public CityController(ICityService service) : base(service)
        {
        }
    }
}
