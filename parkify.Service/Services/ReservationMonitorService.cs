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
                catch (Exception ex)
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

            var toActivate = await db.Reservations
                .Where(r => r.Status == Database.ReservationStatus.Confirmed && r.ReservationStart <= now && r.ReservationEnd > now)
                .ToListAsync();
            foreach (var r in toActivate)
            {
                r.Status = Database.ReservationStatus.Active;
                r.Modified = now;
                _logger.LogInformation($"Rezervacija {r.Id} aktivirana.");
            }

            var toComplete = await db.Reservations
                .Where(r => r.Status == Database.ReservationStatus.Active && r.ReservationEnd <= now)
                .ToListAsync();
            foreach (var r in toComplete)
            {
                r.Status = Database.ReservationStatus.Completed;
                r.Modified = now;
                var spot = await db.ParkingSpots.FirstOrDefaultAsync(s => s.Id == r.ParkingSpotId);
                if (spot != null)
                {
                    spot.IsAvailable = true;
                    spot.Modified = now;
                }
                _logger.LogInformation($"Rezervacija {r.Id} završena.");
            }

            var noShowLimit = now.AddMinutes(-30);
            var toNoShow = await db.Reservations
                .Where(r => r.Status == Database.ReservationStatus.Confirmed && !r.IsCheckedIn && r.ReservationStart <= noShowLimit)
                .ToListAsync();
            foreach (var r in toNoShow)
            {
                r.Status = Database.ReservationStatus.NoShow;
                r.Modified = now;
                var spot = await db.ParkingSpots.FirstOrDefaultAsync(s => s.Id == r.ParkingSpotId);
                if (spot != null)
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
                    r.Status == Database.ReservationStatus.Confirmed &&
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

            _publisher.PublishNotification(new NotificationMessage
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