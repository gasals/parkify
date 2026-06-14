using MapsterMapper;
using parkify.Model.Exceptions;
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
        private readonly IMessagePublisher _publisher;

        public PaymentService(
            Database.ParkifyContext context,
            IMapper mapper,
            IMessagePublisher publisher)
            : base(context, mapper)
        {
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
                throw new UserException("Iznos dopune mora biti veći od 0");

            if (string.IsNullOrWhiteSpace(entity.StripePaymentIntentId))
                throw new UserException("Stripe payment intent je obavezan.");

            if (request.ReservationId.HasValue)
            {
                var reservationExists = Context.Reservations.Any(r => r.Id == request.ReservationId.Value);
                if (!reservationExists)
                    throw new UserException("Rezervacija ne postoji");
            }
            else if (request.WalletId.HasValue)
            {
                var walletExists = Context.Wallets.Any(w => w.Id == request.WalletId.Value);
                if (!walletExists)
                    throw new UserException("Wallet ne postoji");
            }
            else
            {
                throw new UserException("Morate navesti Rezervaciju ili Novčanik");
            }

            base.BeforeInsert(request, entity);
        }

        public async Task<Payment> ConfirmPayment(int paymentId)
        {
            var payment = Context.Payments.FirstOrDefault(p => p.Id == paymentId);

            if (payment == null)
                throw new UserException("Plaćanje nije pronađeno");

            if (payment.Status == Database.PaymentStatus.Completed)
                return Mapper.Map<Payment>(payment);

            if (payment.Status == Database.PaymentStatus.Refunded || payment.Status == Database.PaymentStatus.Failed)
                throw new UserException("Plaćanje je već u terminalnom statusu i ne može biti potvrđeno.");

            var paymentIntentService = new PaymentIntentService();
            var paymentIntent = await paymentIntentService.GetAsync(payment.StripePaymentIntentId);

            if (!string.Equals(paymentIntent.Status, "succeeded", StringComparison.OrdinalIgnoreCase))
            {
                await _publisher.PublishNotificationAsync(new NotificationMessage
                {
                    UserId = payment.UserId,
                    Title = "Plaćanje nije uspjelo",
                    Message = $"Vaše plaćanje nije uspješno završeno. Pokušajte ponovo ili kontaktirajte podršku.",
                    Type = (int)Database.NotificationType.PaymentFailed,
                    Channel = NotificationChannel.Both,
                    ReservationId = payment.ReservationId
                });
                throw new UserException("Stripe plaćanje još nije uspješno završeno.");
            }

            var expectedAmountInPfennig = (long)Math.Round(payment.Amount * 100m, MidpointRounding.AwayFromZero);
            if (paymentIntent.AmountReceived != expectedAmountInPfennig)
                throw new UserException("Stripe iznos se ne podudara sa lokalnim plaćanjem.");

            if (Context.Payments.Any(p =>
                    p.Id != payment.Id &&
                    p.StripePaymentIntentId == payment.StripePaymentIntentId &&
                    p.Status == Database.PaymentStatus.Completed))
            {
                throw new UserException("Ovaj Stripe payment intent je već iskorišten.");
            }

            payment.Status = Database.PaymentStatus.Completed;
            payment.Completed = DateTime.UtcNow;
            payment.TransactionId = paymentIntent.LatestChargeId ?? paymentIntent.Id;
            payment.Modified = DateTime.UtcNow;
            NotificationMessage? notification = null;

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

                    notification = new NotificationMessage
                    {
                        UserId = payment.UserId,
                        Title = "Plaćanje uspješno",
                        Message = $"Vaše plaćanje od {payment.Amount:F2} KM je uspješno obrađeno. " +
                                  $"Rezervacija je potvrđena. Kod: {reservation.ReservationCode}",
                        Type = (int)Database.NotificationType.PaymentSuccessful,
                        Channel = NotificationChannel.Both,
                        ReservationId = reservation.Id
                    };
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

                    notification = new NotificationMessage
                    {
                        UserId = payment.UserId,
                        Title = "Novčanik dopunjen",
                        Message = $"Vaš novčanik je uspješno dopunjen sa {payment.Amount:F2} KM.",
                        Type = (int)Database.NotificationType.PaymentSuccessful,
                        Channel = NotificationChannel.Both
                    };
                }
            }

            Context.SaveChanges();

            if (notification != null)
            {
                await _publisher.PublishNotificationAsync(notification);
            }

            return Mapper.Map<Payment>(payment);
        }

        public async Task<Payment> RefundPayment(int paymentId, string reason)
        {
            var payment = Context.Payments.FirstOrDefault(p => p.Id == paymentId);

            if (payment == null)
                throw new UserException("Plaćanje nije pronađeno.");

            if (payment.Status == Database.PaymentStatus.Refunded)
                return Mapper.Map<Payment>(payment);

            if (payment.Status != Database.PaymentStatus.Completed)
                throw new UserException("Samo završeno plaćanje može biti refundirano.");

            if (string.IsNullOrWhiteSpace(payment.StripePaymentIntentId))
                throw new UserException("Plaćanje nema Stripe payment intent i ne može biti refundirano.");

            var sanitizedReason = reason?.Trim();
            if (string.IsNullOrWhiteSpace(sanitizedReason))
                throw new UserException("Razlog refundacije je obavezan.");

            var paymentIntentService = new PaymentIntentService();
            var paymentIntent = await paymentIntentService.GetAsync(payment.StripePaymentIntentId);

            if (!string.Equals(paymentIntent.Status, "succeeded", StringComparison.OrdinalIgnoreCase))
                throw new UserException("Stripe plaćanje nije u statusu koji dozvoljava refundaciju.");

            var refundService = new RefundService();
            var refund = await refundService.CreateAsync(new RefundCreateOptions
            {
                PaymentIntent = payment.StripePaymentIntentId,
                Reason = RefundReasons.RequestedByCustomer,
                Metadata = new Dictionary<string, string>
                {
                    { "paymentId", payment.Id.ToString() },
                    { "reason", sanitizedReason }
                }
            });

            if (!string.Equals(refund.Status, "succeeded", StringComparison.OrdinalIgnoreCase) &&
                !string.Equals(refund.Status, "pending", StringComparison.OrdinalIgnoreCase))
            {
                throw new UserException("Stripe refundacija nije uspjela.");
            }

            payment.Status = Database.PaymentStatus.Refunded;
            payment.RefundReason = sanitizedReason;
            payment.Refunded = DateTime.UtcNow;
            payment.Modified = DateTime.UtcNow;

            if (payment.ReservationId.HasValue)
            {
                var reservation = Context.Reservations.FirstOrDefault(r => r.Id == payment.ReservationId.Value);
                if (reservation != null)
                {
                    reservation.PaymentAmountPaid = 0;

                    if (reservation.Status == Database.ReservationStatus.Confirmed ||
                        reservation.Status == Database.ReservationStatus.Active)
                    {
                        reservation.Status = Database.ReservationStatus.Cancelled;

                        var parkingZone = Context.ParkingZones.Find(reservation.ParkingZoneId);
                        if (parkingZone != null)
                        {
                            parkingZone.AvailableSpots += 1;
                        }

                        var parkingSpot = Context.ParkingSpots.Find(reservation.ParkingSpotId);
                        if (parkingSpot != null)
                        {
                            parkingSpot.IsAvailable = true;
                            parkingSpot.Modified = DateTime.UtcNow;
                        }
                    }
                }
            }
            else if (payment.WalletId.HasValue)
            {
                var wallet = Context.Wallets.Find(payment.WalletId.Value);
                if (wallet != null)
                {
                    wallet.Balance -= payment.Amount;
                    wallet.Modified = DateTime.UtcNow;

                    Context.WalletTransactions.Add(new Database.WalletTransaction
                    {
                        WalletId = wallet.Id,
                        Amount = -payment.Amount,
                        Type = Database.WalletTransactionType.Refund,
                        Created = DateTime.UtcNow
                    });
                }
            }

            Context.SaveChanges();

            await _publisher.PublishNotificationAsync(new NotificationMessage
            {
                UserId = payment.UserId,
                Title = "Plaćanje refundirano",
                Message = $"Plaćanje od {payment.Amount:F2} KM je refundirano. Razlog: {payment.RefundReason}",
                Type = (int)Database.NotificationType.PaymentRefunded,
                Channel = NotificationChannel.Both,
                ReservationId = payment.ReservationId
            });

            return Mapper.Map<Payment>(payment);
        }
    }
}