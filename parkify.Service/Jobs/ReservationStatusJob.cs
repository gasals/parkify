using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using parkify.RabbitMQ;
using parkify.RabbitMQ.Models;
using parkify.Service.Database;
using parkify.Service.Interfaces;

namespace Parkify.Service.Jobs;

public class ReservationStatusJob : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<ReservationStatusJob> _logger;
    private static readonly TimeSpan _interval = TimeSpan.FromMinutes(10);
    private readonly IMessagePublisher _publisher;

    public ReservationStatusJob(IServiceScopeFactory scopeFactory, ILogger<ReservationStatusJob> logger, IMessagePublisher publisher)
    {
        _scopeFactory  = scopeFactory;
        _logger        = logger;
        _publisher = publisher;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("ReservationStatusJob started.");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await RunAsync(stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "ReservationStatusJob encountered an unhandled exception.");
            }

            await Task.Delay(_interval, stoppingToken);
        }

        _logger.LogInformation("ReservationStatusJob stopped.");
    }

    private async Task RunAsync(CancellationToken ct)
    {
        using var scope = _scopeFactory.CreateScope();

        var db                  = scope.ServiceProvider.GetRequiredService<ParkifyContext>();
        var notificationService = scope.ServiceProvider.GetRequiredService<INotificationService>();

        var now = DateTime.UtcNow;

        await CancelStalePendingAsync(db, now, ct);
        await NoShowExpiredConfirmedAsync(db, now, ct);
        await NotifyOverstayedActiveAsync(db, notificationService, now, ct);
        await NotifyLateArrivalAsync(db, notificationService, now, ct);

        await db.SaveChangesAsync(ct);

        _logger.LogInformation("ReservationStatusJob cycle completed at {Time}.", now);
    }

    private async Task CancelStalePendingAsync(ParkifyContext db, DateTime now, CancellationToken ct)
    {
        var cutoff = now.AddMinutes(-10);

        var stale = await db.Reservations
            .Where(r => r.Status == ReservationStatus.Pending && r.Modified < cutoff)
            .ToListAsync(ct);

        if (stale.Count == 0) return;

        foreach (var r in stale)
        {
            r.Status   = ReservationStatus.Cancelled;
            r.Modified = now;
        }

        _logger.LogInformation("Cancelled {Count} stale pending reservation(s).", stale.Count);
    }

    private async Task NoShowExpiredConfirmedAsync(ParkifyContext db, DateTime now, CancellationToken ct)
    {
        var expired = await db.Reservations
            .Where(r => r.Status == ReservationStatus.Confirmed && r.ReservationEnd < now)
            .ToListAsync(ct);

        if (expired.Count == 0) return;

        foreach (var r in expired)
        {
            r.Status   = ReservationStatus.NoShow;
            r.Modified = now;
        }

        _logger.LogInformation("Marked {Count} confirmed reservation(s) as NoShow.", expired.Count);
    }

    private async Task NotifyOverstayedActiveAsync(
        ParkifyContext db,
        INotificationService notificationService,
        DateTime now,
        CancellationToken ct)
    {
        var overstayed = await db.Reservations
            .Where(r => r.Status == ReservationStatus.Active && r.ReservationEnd < now)
            .ToListAsync(ct);

        if (overstayed.Count == 0) return;

        foreach (var r in overstayed)
        {
            try
            {
                _publisher.PublishNotification(new parkify.RabbitMQ.Models.NotificationMessage
                {
                    UserId  = r.UserId,
                    Title   = "Prekoračenje vremena parkiranja",
                    Message = $"Vaše rezervirano parkiranje je isteklo u " +
                              $"{r.ReservationEnd.ToLocalTime():HH:mm}. " +
                              $"Molimo vas da što prije napustite parking mjesto.",
                    Type    = (int)NotificationType.ReservationReminder,
                    Channel = NotificationChannel.InApp,
                });
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Failed to send overstay notification for reservation {Id}.", r.Id);
            }
        }

        _logger.LogInformation("Sent overstay notification(s) for {Count} active reservation(s).", overstayed.Count);
    }

    private async Task NotifyLateArrivalAsync(
        ParkifyContext db,
        INotificationService notificationService,
        DateTime now,
        CancellationToken ct)
    {
        var lateReservations = await db.Reservations
            .Where(r => r.Status == ReservationStatus.Confirmed
                && r.ReservationStart < now
                && r.ReservationStart >= now.AddMinutes(-10))
            .ToListAsync(ct);

        if (lateReservations.Count == 0) return;

        foreach (var r in lateReservations)
        {
            try
            {
                _publisher.PublishNotification(new parkify.RabbitMQ.Models.NotificationMessage
                {
                    UserId = r.UserId,
                    Title = "Kasnite na parking",
                    Message = $"Vaša rezervacija je počela u " +
                              $"{r.ReservationStart.ToLocalTime():HH:mm}. " +
                              $"Molimo vas da dođete na parking mjesto što prije.",
                    Type = (int)NotificationType.ReservationReminder,
                    Channel = NotificationChannel.InApp,
                });
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex,
                    "Failed to send late arrival notification for reservation {Id}.",
                    r.Id);
            }
        }

        _logger.LogInformation(
            "Sent late arrival notification(s) for {Count} confirmed reservation(s).",
            lateReservations.Count);
    }
}
