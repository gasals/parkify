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

        [HttpGet]
        [AllowAnonymous]
        public override PagedResult<ParkingZone> GetList([FromQuery] ParkingZoneSearch searchObject)
        {
            return base.GetList(searchObject);
        }

        [HttpGet("{id}")]
        [AllowAnonymous]
        public override ParkingZone GetById(int id)
        {
            return base.GetById(id);
        }
    }
}