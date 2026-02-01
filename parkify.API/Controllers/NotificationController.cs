using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using parkify.Model.Helpers;
using parkify.Model.Models;
using parkify.Model.Requests;
using parkify.Model.SearchObject;
using parkify.Service.Interfaces;

namespace parkify.API.Controllers
{
    public class NotificationController : BaseCRUDController<Notification, NotificationSearch, NotificationInsertRequest, NotificationUpdateRequest>
    {
        public NotificationController(INotificationService service) : base(service)
        {
        }

        [HttpGet]
        [AllowAnonymous]
        public override PagedResult<Notification> GetList([FromQuery] NotificationSearch searchObject)
        {
            return base.GetList(searchObject);
        }

        [HttpGet("{id}")]
        [AllowAnonymous]
        public override Notification GetById(int id)
        {
            return base.GetById(id);
        }
    }
}
