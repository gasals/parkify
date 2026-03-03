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
                catch (Exception ex) { _logger.LogError(ex, "Greška u ReservationMonitorService"); }

                await Task.Delay(Interval, stoppingToken);
            }
        }

        private async Task CheckReservationsAsync()
        {
            using var scope = _scopeFactory.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<Database.ParkifyContext>();
            var now = DateTime.UtcNow;

            // Nadolazeće rezervacije u narednih 31 min
            var upcoming = await db.Reservations
                .Where(r =>
                    r.Status == Database.ReservationStatus.Confirmed &&
                    !r.IsCheckedIn &&
                    r.ReservationStart > now &&
                    r.ReservationStart <= now.AddMinutes(31))
                .ToListAsync();

            foreach (var r in upcoming)
            {
                var mins = (r.ReservationStart - now).TotalMinutes;

                if (mins is >= 29 and <= 31)
                    await PublishIfNotSentAsync(db, r.UserId, r.Id,
                        Database.NotificationType.CheckInReminder,
                        "Podsjetnik za rezervaciju",
                        "Vaša rezervacija počinje za 30 minuta.");

                if (mins is >= 14 and <= 16)
                    await PublishIfNotSentAsync(db, r.UserId, r.Id,
                        Database.NotificationType.ReservationReminder,
                        "Rezervacija uskoro!",
                        "Vaša rezervacija počinje za 15 minuta.");
            }

            // Kasni check-in: prošlo 15-16 min od starta, još nema check-in
            var late = await db.Reservations
                .Where(r =>
                    r.Status == Database.ReservationStatus.Confirmed &&
                    !r.IsCheckedIn &&
                    r.ReservationStart <= now.AddMinutes(-15) &&
                    r.ReservationStart >= now.AddMinutes(-16))
                .ToListAsync();

            foreach (var r in late)
                await PublishIfNotSentAsync(db, r.UserId, r.Id,
                    Database.NotificationType.CheckInReminder,
                    "Kasni check-in",
                    "Vaša rezervacija je počela ali još niste odradili check-in. Molimo prijavite se što prije.");
        }

        private async Task PublishIfNotSentAsync(
            Database.ParkifyContext db,
            int userId, int reservationId,
            Database.NotificationType type,
            string title, string message)
        {
            // Idempotency — ne šalji isti tip notifikacije za istu rezervaciju dvaput
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
                Channel = NotificationChannel.Both,
                ReservationId = reservationId
            });
        }
    }
}
