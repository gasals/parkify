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

        /// <summary>
        /// Admin šalje notifikaciju jednom korisniku.
        /// POST /api/Notification/send
        /// </summary>
        [HttpPost("send")]
        [Authorize(Roles = "Admin")]
        public IActionResult SendToUser([FromBody] NotificationInsertRequest request)
        {
            _notificationService.SendToUser(request);
            return Ok(new { Message = "Notifikacija je poslana." });
        }

        /// <summary>
        /// Admin šalje notifikaciju svim korisnicima.
        /// POST /api/Notification/send-all
        /// </summary>
        [HttpPost("send-all")]
        [Authorize(Roles = "Admin")]
        public IActionResult SendToAll([FromBody] NotificationInsertRequest request)
        {
            _notificationService.SendToAll(request);
            return Ok(new { Message = "Notifikacija je poslana svim korisnicima." });
        }

        /// <summary>
        /// Označi notifikaciju kao pročitanu.
        /// PATCH /api/Notification/{id}/read
        /// </summary>
        [HttpPatch("{id}/read")]
        [Authorize]
        public IActionResult MarkAsRead(int id)
        {
            _notificationService.Update(id, new NotificationUpdateRequest { IsRead = true });
            return Ok();
        }
    }
}
