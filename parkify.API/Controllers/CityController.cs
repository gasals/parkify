using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using parkify.Model.Constants;
using parkify.Model.Helpers;
using parkify.Model.Models;
using parkify.Model.Requests;
using parkify.Model.SearchObject;
using parkify.Service.Interfaces;

namespace parkify.API.Controllers
{
    public class CityController : BaseCRUDController<City, CitySearch, CityInsertRequest, CityUpdateRequest>
    {
        public CityController(ICityService service) : base(service)
        {
        }

        [HttpGet]
        [Authorize]
        public override async Task<PagedResult<City>> GetList([FromQuery] CitySearch searchObject)
        {
            return await base.GetList(searchObject);
        }

        [HttpGet("{id}")]
        [Authorize]
        public override async Task<City?> GetById(int id)
        {
            return await base.GetById(id);
        }

        [HttpPost]
        [Authorize(Roles = AppRoles.Admin)]
        public override async Task<City> Insert([FromBody] CityInsertRequest request)
        {
            return await base.Insert(request);
        }

        [HttpPut("{id}")]
        [Authorize(Roles = AppRoles.Admin)]
        public override async Task<City> Update(int id, [FromBody] CityUpdateRequest request)
        {
            return await base.Update(id, request);
        }

        [HttpDelete("{id}")]
        [Authorize(Roles = AppRoles.Admin)]
        public IActionResult Delete(int id)
        {
            return Ok((_service as ICityService)!.Delete(id));
        }
    }
}
