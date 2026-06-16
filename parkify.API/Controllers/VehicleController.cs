using Microsoft.AspNetCore.Mvc;
using parkify.Model.Helpers;
using parkify.Model.Models;
using parkify.Model.Requests;
using parkify.Model.SearchObject;
using parkify.Service.Interfaces;

namespace parkify.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class VehicleController : BaseCRUDController<Vehicle, VehicleSearchObject, VehicleInsertRequest, VehicleUpdateRequest>
    {
        public VehicleController(IVehicleService service) : base(service)
        {
        }

        [HttpGet]
        public override PagedResult<Vehicle> GetList([FromQuery] VehicleSearchObject searchObject)
        {
            if (!IsCurrentUserAdmin())
            {
                searchObject.UserId = GetCurrentUserIdOrThrow();
            }

            return base.GetList(searchObject);
        }

        [HttpGet("{id}")]
        public override Vehicle GetById(int id)
        {
            var vehicle = base.GetById(id);

            if (!IsCurrentUserAdmin() && vehicle.UserId != GetCurrentUserIdOrThrow())
                throw new UnauthorizedAccessException("Nemate pravo pristupa ovom vozilu.");

            return vehicle;
        }

        [HttpPost]
        public override Vehicle Insert([FromBody] VehicleInsertRequest request)
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

            return base.Insert(request);
        }

        [HttpPut("{id}")]
        public override Vehicle Update(int id, [FromBody] VehicleUpdateRequest request)
        {
            if (!IsCurrentUserAdmin())
            {
                var vehicle = base.GetById(id);
                if (vehicle.UserId != GetCurrentUserIdOrThrow())
                    throw new UnauthorizedAccessException("Nemate pravo izmjene ovog vozila.");
            }

            return base.Update(id, request);
        }
    }
}