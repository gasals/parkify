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
        public override ParkingZone Insert(ParkingZoneInsertRequest request)
        {
            return base.Insert(request);
        }

        [HttpPut("{id}")]
        [Authorize(Roles = AppRoles.Admin)]
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

        [HttpGet("recommendations")]
        [Authorize]
        public IActionResult GetRecommendations([FromQuery] int count = 5, [FromQuery] int? userId = null)
        {
            var effectiveUserId = ResolveRecommendationUserId(userId);
            return Ok((_service as IParkingZoneService)!.GetRecommendations(effectiveUserId, count));
        }

        [HttpGet("recommendations/explained")]
        [Authorize]
        public IActionResult GetRecommendationsExplained([FromQuery] int count = 5, [FromQuery] int? userId = null)
        {
            var effectiveUserId = ResolveRecommendationUserId(userId);
            return Ok((_service as IParkingZoneService)!.GetRecommendationsWithExplanation(effectiveUserId, count));
        }

        [HttpDelete("{id}")]
        [Authorize(Roles = AppRoles.Admin)]
        public IActionResult Delete(int id)
        {
            return Ok((_service as IParkingZoneService)!.Delete(id));
        }

        private int ResolveRecommendationUserId(int? requestedUserId)
        {
            if (requestedUserId.HasValue)
            {
                if (!IsCurrentUserAdmin())
                    throw new UnauthorizedAccessException("Nemate pravo pristupa preporukama drugog korisnika.");

                return requestedUserId.Value;
            }

            return GetCurrentUserIdOrThrow();
        }
    }
}