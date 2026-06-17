using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using parkify.RabbitMQ;
using parkify.RabbitMQ.Models;

namespace parkify.Service.Services
{
                        public class ReservationMonitorService : BackgroundService
    {
        private readonly ILogger<ReservationMonitorService> _logger;
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly IMessagePublisher _publisher;

        private static readonly TimeSpan Interval = TimeSpan.FromMinutes(1);

        public ReservationMonitorService(
            ILogger<ReservationMonitorService> logger,
            IServiceScopeFactory scopeFactory,
            IMessagePublisher publisher)
        {
            _logger = logger;
            _scopeFactory = scopeFactory;
            _publisher = publisher;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            while (!stoppingToken.IsCancellationRequested)
            {
                try { await CheckReservationsAsync(); }
                catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
                {
                    break;
                }
                catch (DbUpdateException ex)
                {
                    _logger.LogError(ex, "Greška pri spremanju promjena u ReservationMonitorService");
                }
                catch (InvalidOperationException ex)
                {
                    _logger.LogError(ex, "Greška u ReservationMonitorService");
                }
                await Task.Delay(Interval, stoppingToken);
            }
        }

        private async Task CheckReservationsAsync()
        {
            using var scope = _scopeFactory.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<Database.ParkifyContext>();
            var now = DateTime.UtcNow;

            var staleCutoff = now.AddMinutes(-10);
            var stalePending = await db.Reservations
                .Where(r =>
                    r.Status == Database.ReservationStatus.Pending &&
                    r.FinalPrice > r.PaymentAmountPaid &&
                    r.Modified < staleCutoff)
                .ToListAsync();
            foreach (var r in stalePending)
            {
                r.Status = Database.ReservationStatus.Cancelled;
                r.Modified = now;

                await PublishIfNotSentAsync(
                    db, r.UserId, r.Id,
                    Database.NotificationType.ReservationCancelled,
                    "Rezervacija otkazana",
                    "Rezervacija je automatski otkazana jer uplata nije završena na vrijeme.",
                    NotificationChannel.Both);

                _logger.LogInformation("Rezervacija {ReservationId} otkazana zbog isteka pending perioda.", r.Id);
            }

            var toConfirm = await db.Reservations
                .Where(r =>
                    r.Status == Database.ReservationStatus.Pending &&
                    r.PaymentAmountPaid >= r.FinalPrice &&
                    r.ReservationStart <= now &&
                    r.ReservationEnd > now)
                .ToListAsync();
            foreach (var r in toConfirm)
            {
                r.Status = Database.ReservationStatus.Confirmed;
                r.Modified = now;
                _logger.LogInformation("Rezervacija {ReservationId} potvrđena na početku termina.", r.Id);
            }

            var toComplete = await db.Reservations
                .Where(r => r.Status == Database.ReservationStatus.Active && r.ReservationEnd <= now)
                .ToListAsync();
            var toNoShow = await db.Reservations
                .Where(r =>
                    r.Status == Database.ReservationStatus.Confirmed &&
                    !r.IsCheckedIn &&
                    r.ReservationEnd <= now)
                .ToListAsync();

            var spotIds = toComplete
                .Select(r => r.ParkingSpotId)
                .Concat(toNoShow.Select(r => r.ParkingSpotId))
                .Distinct()
                .ToList();

            var spotsById = await db.ParkingSpots
                .Where(s => spotIds.Contains(s.Id))
                .ToDictionaryAsync(s => s.Id);

            foreach (var r in toComplete)
            {
                r.Status = Database.ReservationStatus.Completed;
                r.Modified = now;
                if (spotsById.TryGetValue(r.ParkingSpotId, out var spot))
                {
                    spot.IsAvailable = true;
                    spot.Modified = now;
                }
                _logger.LogInformation($"Rezervacija {r.Id} završena.");
            }

            foreach (var r in toNoShow)
            {
                r.Status = Database.ReservationStatus.NoShow;
                r.Modified = now;
                if (spotsById.TryGetValue(r.ParkingSpotId, out var spot))
                {
                    spot.IsAvailable = true;
                    spot.Modified = now;
                }
                await PublishIfNotSentAsync(
                    db, r.UserId, r.Id,
                    Database.NotificationType.ReservationCancelled,
                    "Rezervacija nije iskorištena",
                    "Niste se pojavili na vrijeme. Rezervacija je označena kao No-Show i parking mjesto je oslobođeno.",
                    NotificationChannel.InApp);
                _logger.LogInformation($"Rezervacija {r.Id} označena kao No-Show.");
            }

            var upcoming = await db.Reservations
                .Where(r =>
                    r.Status == Database.ReservationStatus.Pending &&
                    r.PaymentAmountPaid >= r.FinalPrice &&
                    !r.IsCheckedIn &&
                    r.ReservationStart > now.AddMinutes(9) &&
                    r.ReservationStart <= now.AddMinutes(11))
                .ToListAsync();
            foreach (var r in upcoming)
            {
                await PublishIfNotSentAsync(
                    db, r.UserId, r.Id,
                    Database.NotificationType.ReservationReminder,
                    "Rezervacija za 10 minuta",
                    "Vaša rezervacija počinje za 10 minuta. Budite na vrijeme!",
                    NotificationChannel.Both);
            }

            var lateCheckIn = await db.Reservations
                .Where(r =>
                    r.Status == Database.ReservationStatus.Confirmed &&
                    !r.IsCheckedIn &&
                    r.ReservationStart <= now.AddMinutes(-9) &&
                    r.ReservationStart >= now.AddMinutes(-11))
                .ToListAsync();
            foreach (var r in lateCheckIn)
            {
                await PublishIfNotSentAsync(
                    db, r.UserId, r.Id,
                    Database.NotificationType.CheckInReminder,
                    "Zaboravili ste check-in",
                    "Vaša rezervacija je počela prije 10 minuta, a još niste odradili check-in.",
                    NotificationChannel.InApp);
            }

            await db.SaveChangesAsync();
        }

        private async Task PublishIfNotSentAsync(
            Database.ParkifyContext db,
            int userId,
            int reservationId,
            Database.NotificationType type,
            string title,
            string message,
            NotificationChannel channel)
        {
                        var alreadySent = await db.Notifications.AnyAsync(n =>
                n.UserId == userId &&
                n.ReservationId == reservationId &&
                n.Type == type);

            if (alreadySent) return;

            await _publisher.PublishNotificationAsync(new NotificationMessage
            {
                UserId = userId,
                Title = title,
                Message = message,
                Type = (int)type,
                Channel = channel,
                ReservationId = reservationId
            });

            _logger.LogInformation(
                "Objavljena {Type} notifikacija za rezervaciju {ReservationId}",
                type, reservationId);
        }
    }
}