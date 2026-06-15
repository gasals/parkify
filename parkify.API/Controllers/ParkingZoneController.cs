using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using parkify.Model.Helpers;
using parkify.Model.Models;
using parkify.Model.Requests;
using parkify.Model.SearchObject;
using parkify.Service.Interfaces;

namespace parkify.API.Controllers
{
    public class ParkingZonesController : BaseCRUDController<ParkingZone, ParkingZoneSearch, ParkingZoneInsertRequest, ParkingZoneUpdateRequest>
    {
        public ParkingZonesController(IParkingZoneService service) : base(service)
        {
        }

        [HttpPost]
        [Authorize(Roles = "Admin")]
        public override ParkingZone Insert(ParkingZoneInsertRequest request)
        {
            return base.Insert(request);
        }

        [HttpPut("{id}")]
        [Authorize(Roles = "Admin")]
        public override ParkingZone Update(int id, ParkingZoneUpdateRequest request)
        {
            return base.Update(id, request);
        }

        [HttpGet]
        [Authorize]
        public override PagedResult<ParkingZone> GetList([FromQuery] ParkingZoneSearch searchObject)
        {
            return base.GetList(searchObject);
        }

        [HttpGet("{id}")]
        [Authorize]
        public override ParkingZone GetById(int id)
        {
            return base.GetById(id);
        }

        [HttpGet("recommendations/{userId}")]
        [Authorize]
        public IActionResult GetRecommendations(int userId, [FromQuery] int count = 5)
        {
            return Ok((_service as IParkingZoneService)!.GetRecommendations(userId, count));
        }

        [HttpGet("recommendations/{userId}/explained")]
        [Authorize]
        public IActionResult GetRecommendationsExplained(int userId, [FromQuery] int count = 5)
        {
            return Ok((_service as IParkingZoneService)!.GetRecommendationsWithExplanation(userId, count));
        }

        [HttpDelete("{id}")]
        [Authorize(Roles = "Admin")]
        public IActionResult Delete(int id)
        {
            return Ok((_service as IParkingZoneService)!.Delete(id));
        }
    }
}