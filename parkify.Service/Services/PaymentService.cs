using MapsterMapper;
using parkify.Model.Models;
using parkify.Model.Requests;
using parkify.Model.SearchObject;
using parkify.Service.Interfaces;

namespace parkify.Service.Services
{
    public class PaymentService 
        : BaseCRUDService<Payment, PaymentSearch, Database.Payment, PaymentInsertRequest, PaymentUpdateRequest>,
          IPaymentService
    {
        public PaymentService(Database.ParkifyContext context, IMapper mapper)
            : base(context, mapper)
        {
        }

        public override IQueryable<Database.Payment> AddFilter(PaymentSearch search, IQueryable<Database.Payment> query)
        {
            query = base.AddFilter(search, query);

            if (search?.UserId.HasValue == true)
            {
                query = query.Where(x => x.UserId == search.UserId);
            }

            if (search?.ReservationId.HasValue == true)
            {
                query = query.Where(x => x.ReservationId == search.ReservationId);
            }

            if (search?.Status.HasValue == true)
            {
                query = query.Where(x => (int)x.Status == search.Status);
            }

            return query;
        }
    }
}
