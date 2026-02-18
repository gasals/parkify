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
        private readonly IReservationService _reservationService;

        public PaymentService(Database.ParkifyContext context, IMapper mapper, IReservationService reservationService)
            : base(context, mapper)
        {
            _reservationService = reservationService;
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

        public override void BeforeInsert(PaymentInsertRequest request, Database.Payment entity)
        {
            entity.PaymentCode = Guid.NewGuid().ToString();

            var reservation = _reservationService.GetById(request.ReservationId);
            if (reservation == null)
            {
                throw new Exception("Rezervacija ne postoji");
            }

            entity.Status = Database.PaymentStatus.Pending;
            entity.Created = DateTime.UtcNow;

            base.BeforeInsert(request, entity);
        }

        public async Task<Payment> ConfirmPayment(int paymentId)
        {
            var payment = GetById(paymentId);

            if (payment == null)
            {
                throw new Exception("Plaćanje nije pronađeno");
            }

            if (payment.Status != 1 && payment.Status != 2)
            {
                throw new Exception("Samo plaćanja sa statusom Pending ili Processing se mogu potvrditi");
            }

            var updateRequest = new PaymentUpdateRequest
            {
                Status = 3,
            };

            Update(paymentId, updateRequest);

            payment.Status = (int)Database.PaymentStatus.Completed;
            payment.Completed = DateTime.UtcNow;

            return payment;
        }

        public async Task<Payment> RefundPayment(int paymentId, string reason)
        {
            var payment = GetById(paymentId);

            if (payment == null)
            {
                throw new Exception("Plaćanje nije pronađeno");
            }

            if (payment.Status != 3)
            {
                throw new Exception("Samo potvrđena plaćanja se mogu vratiti");
            }

            var updateRequest = new PaymentUpdateRequest
            {
                Status = 5,
            };

            Update(paymentId, updateRequest);

            var reservationUpdate = new ReservationUpdateRequest
            {
                Status = 5 
            };
            _reservationService.Update(payment.ReservationId, reservationUpdate);

            payment.Status = 5;
            payment.Refunded = DateTime.UtcNow;
            payment.RefundReason = reason;

            return payment;
        }
    }
}