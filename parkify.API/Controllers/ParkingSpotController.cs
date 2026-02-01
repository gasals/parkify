using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
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

        [HttpGet]
        [AllowAnonymous]
        public override PagedResult<ParkingSpot> GetList([FromQuery] ParkingSpotSearch searchObject)
        {
            return base.GetList(searchObject);
        }

        [HttpGet("{id}")]
        [AllowAnonymous]
        public override ParkingSpot GetById(int id)
        {
            return base.GetById(id);
        }
    }
}