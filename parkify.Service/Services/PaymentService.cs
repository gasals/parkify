using MapsterMapper;
using parkify.Model.Models;
using parkify.Model.Requests;
using parkify.Model.SearchObject;
using parkify.RabbitMQ;
using parkify.RabbitMQ.Models;
using parkify.Service.Interfaces;
using Stripe;

namespace parkify.Service.Services
{
    public class PaymentService
        : BaseCRUDService<Payment, PaymentSearch, Database.Payment, PaymentInsertRequest, PaymentUpdateRequest>,
          IPaymentService
    {
        private readonly IReservationService _reservationService;
        private readonly IWalletService _walletService;
        private readonly IMessagePublisher _publisher;

        public PaymentService(
            Database.ParkifyContext context,
            IMapper mapper,
            IReservationService reservationService,
            IWalletService walletService,
            IMessagePublisher publisher)
            : base(context, mapper)
        {
            _reservationService = reservationService;
            _walletService = walletService;
            _publisher = publisher;
        }

        public override IQueryable<Database.Payment> AddFilter(PaymentSearch search, IQueryable<Database.Payment> query)
        {
            query = base.AddFilter(search, query);

            if (search?.UserId.HasValue == true)
                query = query.Where(x => x.UserId == search.UserId);

            if (search?.ReservationId.HasValue == true)
                query = query.Where(x => x.ReservationId == search.ReservationId);

            if (search?.WalletId.HasValue == true)
                query = query.Where(x => x.WalletId == search.WalletId);

            if (search?.Status.HasValue == true)
                query = query.Where(x => (int)x.Status == search.Status);

            return query;
        }

        public override void BeforeInsert(PaymentInsertRequest request, Database.Payment entity)
        {
            entity.PaymentCode = Guid.NewGuid().ToString();
            entity.Status = Database.PaymentStatus.Pending;
            entity.Created = DateTime.UtcNow;
            entity.StripePaymentIntentId = request.StripePaymentIntentId?.Trim() ?? string.Empty;

            if (entity.Amount <= 0)
                throw new Exception("Iznos dopune mora biti veći od 0");

            if (string.IsNullOrWhiteSpace(entity.StripePaymentIntentId))
                throw new Exception("Stripe payment intent je obavezan.");

            if (request.ReservationId.HasValue)
            {
                var reservation = _reservationService.GetById(request.ReservationId.Value);
                if (reservation == null)
                    throw new Exception("Rezervacija ne postoji");
            }
            else if (request.WalletId.HasValue)
            {
                var wallet = _walletService.GetById(request.WalletId.Value);
                if (wallet == null)
                    throw new Exception("Wallet ne postoji");
            }
            else
            {
                throw new Exception("Morate navesti Rezervaciju ili Novčanik");
            }

            base.BeforeInsert(request, entity);
        }

        public async Task<Payment> ConfirmPayment(int paymentId)
        {
            var payment = Context.Payments.FirstOrDefault(p => p.Id == paymentId);

            if (payment == null)
                throw new Exception("Plaćanje nije pronađeno");

            if (payment.Status == Database.PaymentStatus.Completed)
                return Mapper.Map<Payment>(payment);

            if (payment.Status == Database.PaymentStatus.Refunded || payment.Status == Database.PaymentStatus.Failed)
                throw new Exception("Plaćanje je već u terminalnom statusu i ne može biti potvrđeno.");

            var paymentIntentService = new PaymentIntentService();
            var paymentIntent = await paymentIntentService.GetAsync(payment.StripePaymentIntentId);

            if (!string.Equals(paymentIntent.Status, "succeeded", StringComparison.OrdinalIgnoreCase))
                throw new Exception("Stripe plaćanje još nije uspješno završeno.");

            var expectedAmountInPfennig = (long)Math.Round(payment.Amount * 100m, MidpointRounding.AwayFromZero);
            if (paymentIntent.AmountReceived != expectedAmountInPfennig)
                throw new Exception("Stripe iznos se ne podudara sa lokalnim plaćanjem.");

            if (Context.Payments.Any(p =>
                    p.Id != payment.Id &&
                    p.StripePaymentIntentId == payment.StripePaymentIntentId &&
                    p.Status == Database.PaymentStatus.Completed))
            {
                throw new Exception("Ovaj Stripe payment intent je već iskorišten.");
            }

            payment.Status = Database.PaymentStatus.Completed;
            payment.Completed = DateTime.UtcNow;
            payment.TransactionId = paymentIntent.LatestChargeId ?? paymentIntent.Id;
            payment.Modified = DateTime.UtcNow;

            if (payment.ReservationId.HasValue)
            {
                var reservation = Context.Reservations.Find(payment.ReservationId.Value);
                if (reservation != null)
                {
                    reservation.PaymentAmountPaid = payment.Amount;
                    reservation.Status = Database.ReservationStatus.Confirmed;

                    var parkingZone = Context.ParkingZones.Find(reservation.ParkingZoneId);
                    if (parkingZone != null && parkingZone.AvailableSpots > 0)
                    {
                        parkingZone.AvailableSpots -= 1;
                    }

                    var parkingSpot = Context.ParkingSpots.Find(reservation.ParkingSpotId);
                    if (parkingSpot != null)
                    {
                        parkingSpot.IsAvailable = false;
                        parkingSpot.Modified = DateTime.UtcNow;
                    }

                    Context.SaveChanges();

                    _publisher.PublishNotification(new NotificationMessage
                    {
                        UserId = payment.UserId,
                        Title = "Plaćanje uspješno",
                        Message = $"Vaše plaćanje od {payment.Amount:F2} KM je uspješno obrađeno. " +
                                  $"Rezervacija je potvrđena. Kod: {reservation.ReservationCode}",
                        Type = (int)Database.NotificationType.PaymentSuccessful,
                        Channel = NotificationChannel.Both,
                        ReservationId = reservation.Id
                    });
                }
            }
            else if (payment.WalletId.HasValue)
            {
                var wallet = Context.Wallets.Find(payment.WalletId.Value);
                if (wallet != null)
                {
                    wallet.Balance += payment.Amount;
                    wallet.Modified = DateTime.UtcNow;

                    Context.WalletTransactions.Add(new Database.WalletTransaction
                    {
                        WalletId = wallet.Id,
                        Amount = payment.Amount,
                        Type = Database.WalletTransactionType.TopUp,
                        Created = DateTime.UtcNow
                    });

                    Context.SaveChanges();

                     _publisher.PublishNotification(new NotificationMessage
                    {
                        UserId = payment.UserId,
                        Title = "Novčanik dopunjen",
                        Message = $"Vaš novčanik je uspješno dopunjen sa {payment.Amount:F2} KM.",
                        Type = (int)Database.NotificationType.PaymentSuccessful,
                        Channel = NotificationChannel.Both
                    });
                }
            }

            Context.SaveChanges();

            return Mapper.Map<Payment>(payment);
        }
    }
}