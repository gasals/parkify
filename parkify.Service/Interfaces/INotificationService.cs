using parkify.Model.Models;
using parkify.Model.Requests;
using parkify.Model.SearchObject;

namespace parkify.Service.Interfaces
{
    public interface INotificationService
        : ICRUDService<Notification, NotificationSearch, NotificationInsertRequest, NotificationUpdateRequest>
    {
        Task SendToUser(NotificationInsertRequest request);
        Task SendToAll(NotificationInsertRequest request);
    }
}
