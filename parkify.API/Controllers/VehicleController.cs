using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using parkify.Model.Helpers;
using parkify.Model.Models;
using parkify.Model.Requests;
using parkify.Model.SearchObject;
using parkify.Service.Interfaces;

namespace parkify.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class VehicleController : BaseCRUDController<Vehicle, VehicleSearchObject, VehicleInsertRequest, VehicleUpdateRequest>
    {
        public VehicleController(IVehicleService service) : base(service)
        {
        }

        [HttpGet]
        public override async Task<PagedResult<Vehicle>> GetList([FromQuery] VehicleSearchObject searchObject)
        {
            if (!IsCurrentUserAdmin())
            {
                searchObject.UserId = GetCurrentUserIdOrThrow();
            }

            return await base.GetList(searchObject);
        }

        [HttpGet("{id}")]
        public override async Task<Vehicle?> GetById(int id)
        {
            var vehicle = await base.GetById(id);

            if (vehicle == null)
                return null;

            if (!IsCurrentUserAdmin() && vehicle.UserId != GetCurrentUserIdOrThrow())
                throw new UnauthorizedAccessException("Nemate pravo pristupa ovom vozilu.");

            return vehicle;
        }

        [HttpPost]
        public override async Task<Vehicle> Insert([FromBody] VehicleInsertRequest request)
        {
            var currentUserId = GetCurrentUserIdOrThrow();
            if (!IsCurrentUserAdmin())
            {
                request.UserId = currentUserId;
            }
            else if (request.UserId <= 0)
            {
                request.UserId = currentUserId;
            }

            return await base.Insert(request);
        }

        [HttpPut("{id}")]
        public override async Task<Vehicle> Update(int id, [FromBody] VehicleUpdateRequest request)
        {
            if (!IsCurrentUserAdmin())
            {
                var vehicle = await base.GetById(id);
                if (vehicle == null)
                    throw new UnauthorizedAccessException("Vozilo nije pronađeno.");

                if (vehicle.UserId != GetCurrentUserIdOrThrow())
                    throw new UnauthorizedAccessException("Nemate pravo izmjene ovog vozila.");
            }

            return await base.Update(id, request);
        }
    }
}