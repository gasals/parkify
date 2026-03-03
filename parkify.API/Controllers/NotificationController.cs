using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using parkify.Model.Helpers;
using parkify.Model.Models;
using parkify.Model.Requests;
using parkify.Model.SearchObject;
using parkify.Service.Interfaces;

namespace parkify.API.Controllers
{
    public class NotificationController
        : BaseCRUDController<Notification, NotificationSearch, NotificationInsertRequest, NotificationUpdateRequest>
    {
        private readonly INotificationService _notificationService;

        public NotificationController(INotificationService service) : base(service)
        {
            _notificationService = service;
        }

        [HttpGet]
        [Authorize]
        public override PagedResult<Notification> GetList([FromQuery] NotificationSearch searchObject)
            => base.GetList(searchObject);

        [HttpGet("{id}")]
        [Authorize]
        public override Notification GetById(int id)
            => base.GetById(id);

        [HttpPost("send")]
        [Authorize(Roles = "Admin")]
        public IActionResult SendToUser([FromBody] NotificationInsertRequest request)
        {
            _notificationService.SendToUser(request);
            return Ok(new { Message = "Notifikacija je poslana." });
        }

        [HttpPost("send-all")]
        [Authorize(Roles = "Admin")]
        public IActionResult SendToAll([FromBody] NotificationInsertRequest request)
        {
            _notificationService.SendToAll(request);
            return Ok(new { Message = "Notifikacija je poslana svim korisnicima." });
        }

        [HttpPatch("{id}/read")]
        [Authorize]
        public IActionResult MarkAsRead(int id)
        {
            _notificationService.Update(id, new NotificationUpdateRequest { IsRead = true });
            return Ok();
        }
    }
}
