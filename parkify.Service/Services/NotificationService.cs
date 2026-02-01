using MapsterMapper;
using parkify.Model.Models;
using parkify.Model.Requests;
using parkify.Model.SearchObject;
using parkify.Service.Interfaces;

namespace parkify.Service.Services
{
    public class NotificationService 
        : BaseCRUDService<Notification, NotificationSearch, Database.Notification, NotificationInsertRequest, NotificationUpdateRequest>,
          INotificationService
    {
        public NotificationService(Database.ParkifyContext context, IMapper mapper)
            : base(context, mapper)
        {
        }

        public override IQueryable<Database.Notification> AddFilter(NotificationSearch search, IQueryable<Database.Notification> query)
        {
            query = base.AddFilter(search, query);

            if (search?.UserId.HasValue == true)
            {
                query = query.Where(x => x.UserId == search.UserId);
            }

            if (search?.IsRead.HasValue == true)
            {
                query = query.Where(x => x.IsRead == search.IsRead);
            }

            return query;
        }
    }
}
