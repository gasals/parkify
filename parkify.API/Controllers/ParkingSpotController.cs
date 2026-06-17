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
    public class ParkingSpotsController : BaseCRUDController<ParkingSpot, ParkingSpotSearch, ParkingSpotInsertRequest, ParkingSpotUpdateRequest>
    {
        public ParkingSpotsController(IParkingSpotService service) : base(service)
        {
        }

        [HttpPost]
        [Authorize(Roles = AppRoles.Admin)]
        public override async Task<ParkingSpot> Insert(ParkingSpotInsertRequest request)
        {
            return await base.Insert(request);
        }

        [HttpPut("{id}")]
        [Authorize(Roles = AppRoles.Admin)]
        public override async Task<ParkingSpot> Update(int id, ParkingSpotUpdateRequest request)
        {
            return await base.Update(id, request);
        }

        [HttpGet]
        public override async Task<PagedResult<ParkingSpot>> GetList([FromQuery] ParkingSpotSearch searchObject)
        {
            return await base.GetList(searchObject);
        }

        [HttpGet("{id}")]
        public override async Task<ParkingSpot?> GetById(int id)
        {
            return await base.GetById(id);
        }

        [HttpDelete("{id}")]
        [Authorize(Roles = AppRoles.Admin)]
        public IActionResult Delete(int id)
        {
            return Ok((_service as IParkingSpotService)!.Delete(id));
        }
    }
}