using MapsterMapper;
using parkify.Model.Models;
using parkify.Model.Requests;
using parkify.Model.SearchObject;
using parkify.RabbitMQ;
using parkify.RabbitMQ.Models;
using parkify.Service.Interfaces;

namespace parkify.Service.Services
{
    public class NotificationService
        : BaseCRUDService<Notification, NotificationSearch, Database.Notification, NotificationInsertRequest, NotificationUpdateRequest>,
          INotificationService
    {
        private readonly IMessagePublisher _publisher;

        public NotificationService(
            Database.ParkifyContext context,
            IMapper mapper,
            IMessagePublisher publisher)
            : base(context, mapper)
        {
            _publisher = publisher;
        }

        public override IQueryable<Database.Notification> AddFilter(
            NotificationSearch search,
            IQueryable<Database.Notification> query)
        {
            query = base.AddFilter(search, query);

            if (search?.UserId.HasValue == true)
                query = query.Where(x => x.UserId == search.UserId);

            if (search?.IsRead.HasValue == true)
                query = query.Where(x => x.IsRead == search.IsRead);

            return query.OrderByDescending(x => x.Created);
        }

        public override void BeforeUpdate(
            NotificationUpdateRequest request,
            Database.Notification entity)
        {
            if (request.IsRead && !entity.IsRead)
            {
                entity.IsRead = true;
                entity.ReadDate = DateTime.UtcNow;
            }
            base.BeforeUpdate(request, entity);
        }

        public async Task SendToUser(NotificationInsertRequest request)
        {
            await _publisher.PublishNotificationAsync(new NotificationMessage
            {
                UserId = request.UserId,
                Title = request.Title,
                Message = request.Message,
                Type = request.Type,
                Channel = (NotificationChannel)(request.Channel ?? (int)NotificationChannel.InApp),
                ReservationId = request.ReservationId,
                ParkingZoneId = request.ParkingZoneId
            });
        }

        public async Task SendToAll(NotificationInsertRequest request)
        {
            var userIds = Context.Users
                .Where(u => u.IsActive)
                .Select(u => u.Id)
                .ToList();

            var publishTasks = new List<Task>(userIds.Count);

            foreach (var userId in userIds)
            {
                publishTasks.Add(_publisher.PublishNotificationAsync(new NotificationMessage
                {
                    UserId = userId,
                    Title = request.Title,
                    Message = request.Message,
                    Type = request.Type,
                    Channel = (NotificationChannel)(request.Channel ?? (int)NotificationChannel.InApp),
                    ReservationId = request.ReservationId,
                    ParkingZoneId = request.ParkingZoneId
                }));
            }

            await Task.WhenAll(publishTasks);
        }

        public void SendSpecialOfferToAll(string title, string message)
        {
            var userIds = Context.Users
                .Where(u => u.IsActive)
                .Select(u => u.Id)
                .ToList();

            foreach (var userId in userIds)
            {
                _ = _publisher.PublishNotificationAsync(new NotificationMessage
                {
                    UserId = userId,
                    Title = title,
                    Message = message,
                    Type = (int)NotificationType.SpecialOffer,
                    Channel = NotificationChannel.Both
                });
            }
        }
    }
}
