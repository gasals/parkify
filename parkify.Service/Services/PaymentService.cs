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
        private readonly IWalletService _walletService;

        public PaymentService(Database.ParkifyContext context, IMapper mapper, IReservationService reservationService, IWalletService walletService)
            : base(context, mapper)
        {
            _reservationService = reservationService;
            _walletService = walletService;

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

            if (search?.WalletId.HasValue == true)
            {
                query = query.Where(x => x.WalletId == search.WalletId);
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
            entity.Status = Database.PaymentStatus.Pending;
            entity.Created = DateTime.UtcNow;

            if (entity.Amount <= 0)
            {
                throw new Exception("Iznos dopune mora biti veći od 0");
            }

            if (request.ReservationId.HasValue)
            {
                var reservation = _reservationService.GetById(request.ReservationId.Value);
                if (reservation == null)
                {
                    throw new Exception("Rezervacija ne postoji");
                }
            }
            else if (request.WalletId.HasValue)
            {
                var wallet = _walletService.GetById(request.WalletId.Value);
                if (wallet == null)
                {
                    throw new Exception("Wallet ne postoji");
                }
            }
            else
            {
                throw new Exception("Morate navesti Rezervaciju ili Novčanik");
            }

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

            if (payment.WalletId.HasValue)
            {
                var wallet = Context.Wallets.Find(payment.WalletId.Value);
                if (wallet != null)
                {
                    wallet.Balance += payment.Amount;
                    wallet.Modified = DateTime.UtcNow;
                    Context.Wallets.Update(wallet);
                    Context.SaveChanges();
                }
            }


            return payment;
        }
    }
}