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
    public class ParkingZonesController : BaseCRUDController<ParkingZone, ParkingZoneSearch, ParkingZoneInsertRequest, ParkingZoneUpdateRequest>
    {
        public ParkingZonesController(IParkingZoneService service) : base(service)
        {
        }

        [HttpPost]
        [Authorize(Roles = AppRoles.Admin)]
        public override async Task<ParkingZone> Insert(ParkingZoneInsertRequest request)
        {
            return await base.Insert(request);
        }

        [HttpPut("{id}")]
        [Authorize(Roles = AppRoles.Admin)]
        public override async Task<ParkingZone> Update(int id, ParkingZoneUpdateRequest request)
        {
            return await base.Update(id, request);
        }

        [HttpGet]
        [Authorize]
        public override async Task<PagedResult<ParkingZone>> GetList([FromQuery] ParkingZoneSearch searchObject)
        {
            return await base.GetList(searchObject);
        }

        [HttpGet("{id}")]
        [Authorize]
        public override async Task<ParkingZone?> GetById(int id)
        {
            return await base.GetById(id);
        }

        [HttpGet("recommendations")]
        [Authorize]
        public async Task<IActionResult> GetRecommendations([FromQuery] int count = 5)
        {
            var currentUserId = GetCurrentUserIdOrThrow();
            return Ok(await (_service as IParkingZoneService)!.GetRecommendations(currentUserId, count));
        }

        [HttpGet("recommendations/explained")]
        [Authorize]
        public async Task<IActionResult> GetRecommendationsExplained([FromQuery] int count = 5)
        {
            var currentUserId = GetCurrentUserIdOrThrow();
            return Ok(await (_service as IParkingZoneService)!.GetRecommendationsWithExplanation(currentUserId, count));
        }

        [HttpGet("recommendations/admin/{userId:int}")]
        [Authorize(Roles = AppRoles.Admin)]
        public async Task<IActionResult> GetRecommendationsForAdmin(int userId, [FromQuery] int count = 5)
        {
            return Ok(await (_service as IParkingZoneService)!.GetRecommendations(userId, count));
        }

        [HttpGet("recommendations/explained/admin/{userId:int}")]
        [Authorize(Roles = AppRoles.Admin)]
        public async Task<IActionResult> GetRecommendationsExplainedForAdmin(int userId, [FromQuery] int count = 5)
        {
            return Ok(await (_service as IParkingZoneService)!.GetRecommendationsWithExplanation(userId, count));
        }

        [HttpDelete("{id}")]
        [Authorize(Roles = AppRoles.Admin)]
        public IActionResult Delete(int id)
        {
            return Ok((_service as IParkingZoneService)!.Delete(id));
        }

    }
}