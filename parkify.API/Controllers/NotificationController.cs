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
        public override async Task<PagedResult<Notification>> GetList([FromQuery] NotificationSearch searchObject)
        {
            if (!IsCurrentUserAdmin())
            {
                searchObject.UserId = GetCurrentUserIdOrThrow();
            }

            return await base.GetList(searchObject);
        }

        [HttpGet("{id}")]
        [Authorize]
        public override async Task<Notification?> GetById(int id)
        {
            var notification = await base.GetById(id);

            if (notification == null)
                return null;

            if (!IsCurrentUserAdmin() && notification.UserId != GetCurrentUserIdOrThrow())
                throw new UnauthorizedAccessException("Nemate pravo pristupa ovoj notifikaciji.");

            return notification;
        }

        [HttpPost("send")]
        [Authorize(Roles = AppRoles.Admin)]
        public async Task<IActionResult> SendToUser([FromBody] NotificationInsertRequest request)
        {
            await _notificationService.SendToUser(request);
            return Ok(new { Message = "Notifikacija je poslana." });
        }

        [HttpPost("send-all")]
        [Authorize(Roles = AppRoles.Admin)]
        public async Task<IActionResult> SendToAll([FromBody] NotificationInsertRequest request)
        {
            await _notificationService.SendToAll(request);
            return Ok(new { Message = "Notifikacija je poslana svim korisnicima." });
        }

        [HttpPatch("{id}/read")]
        [Authorize]
        public async Task<IActionResult> MarkAsRead(int id)
        {
            if (!IsCurrentUserAdmin())
            {
                var notification = await base.GetById(id);
                if (notification == null)
                    return NotFound();

                if (notification.UserId != GetCurrentUserIdOrThrow())
                    throw new UnauthorizedAccessException("Nemate pravo izmjene ove notifikacije.");
            }

            await _notificationService.Update(id, new NotificationUpdateRequest { IsRead = true });
            return Ok();
        }
    }
}
