using System.Text;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using parkify.RabbitMQ;
using parkify.RabbitMQ.Models;
using parkify.RabbitMQ.Settings;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;

namespace parkify.Service.Services
{
    public class NotificationConsumerService : BackgroundService
    {
        private readonly ILogger<NotificationConsumerService> _logger;
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly RabbitMQConnection _connection;
        private readonly RabbitMQSettings _settings;
        private IChannel? _channel;

        public NotificationConsumerService(
            ILogger<NotificationConsumerService> logger,
            IServiceScopeFactory scopeFactory,
            RabbitMQConnection connection,
            RabbitMQSettings settings)
        {
            _logger = logger;
            _scopeFactory = scopeFactory;
            _connection = connection;
            _settings = settings;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _channel = await _connection.CreateChannelAsync();

            await _channel.BasicQosAsync(
                prefetchSize: 0,
                prefetchCount: 1,
                global: false,
                cancellationToken: stoppingToken);

            var consumer = new AsyncEventingBasicConsumer(_channel);

            consumer.ReceivedAsync += async (_, ea) =>
            {
                try
                {
                    var json = Encoding.UTF8.GetString(ea.Body.ToArray());
                    var message = JsonSerializer.Deserialize<NotificationMessage>(json);

                    if (message != null)
                        await ProcessMessageAsync(message);

                    await _channel.BasicAckAsync(ea.DeliveryTag, multiple: false);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Greška pri obradi notifikacije");
                    await _channel.BasicNackAsync(ea.DeliveryTag, multiple: false, requeue: true);
                }
            };

            await _channel.BasicConsumeAsync(
                queue: _settings.NotificationQueue,
                autoAck: false,
                consumer: consumer,
                cancellationToken: stoppingToken);

            await Task.Delay(Timeout.Infinite, stoppingToken);
        }

        private async Task ProcessMessageAsync(NotificationMessage message)
        {
            using var scope = _scopeFactory.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<Database.ParkifyContext>();
            var emailService = scope.ServiceProvider.GetRequiredService<IEmailService>();

            var user = await db.Users.FirstOrDefaultAsync(u => u.Id == message.UserId);
            if (user == null)
            {
                _logger.LogWarning("Korisnik {UserId} nije pronađen", message.UserId);
                return;
            }

            if (message.Channel == NotificationChannel.InApp ||
                message.Channel == NotificationChannel.Both)
            {
                db.Notifications.Add(new Database.Notification
                {
                    UserId = message.UserId,
                    Title = message.Title,
                    Message = message.Message,
                    Type = (Database.NotificationType)message.Type,
                    ReservationId = message.ReservationId,
                    ParkingZoneId = message.ParkingZoneId,
                    IsRead = false,
                    Created = DateTime.UtcNow
                });
                await db.SaveChangesAsync();
                _logger.LogInformation("In-app notifikacija spremljena za korisnika {UserId}", message.UserId);
            }

            if (message.Channel == NotificationChannel.Email ||
                message.Channel == NotificationChannel.Both)
            {
                var preference = await db.Preferences
                    .FirstOrDefaultAsync(p => p.UserId == message.UserId);

                var isOffer = message.Type == (int)Database.NotificationType.SpecialOffer;
                var notifyAboutOffers = preference?.NotifyAboutOffers ?? true;
                var canSendEmail = !isOffer || notifyAboutOffers;

                if (canSendEmail && !string.IsNullOrEmpty(user.Email))
                {
                    await emailService.SendAsync(
                        to: user.Email,
                        subject: message.Title,
                        body: BuildEmailBody(message, user.FirstName ?? user.Username));

                    _logger.LogInformation("Email poslan na {Email}", user.Email);
                }
                else if (isOffer && !notifyAboutOffers)
                {
                    _logger.LogInformation(
                        "Email preskočen za korisnika {UserId} — NotifyAboutOffers je isključen",
                        message.UserId);
                }
            }
        }

        private static string BuildEmailBody(NotificationMessage msg, string name) =>
            $"""
            <html>
            <body style="font-family:Arial,sans-serif;color:#333;max-width:600px;margin:0 auto">
              <div style="background:#6366F1;padding:24px;border-radius:8px 8px 0 0">
                <h1 style="color:white;margin:0">Parkify</h1>
              </div>
              <div style="padding:24px;border:1px solid #e5e7eb;border-top:none;border-radius:0 0 8px 8px">
                <p>Pozdrav, <strong>{name}</strong>!</p>
                <h2 style="color:#6366F1">{msg.Title}</h2>
                <p>{msg.Message}</p>
                <hr style="border:none;border-top:1px solid #e5e7eb;margin:24px 0" />
                <p style="color:#9ca3af;font-size:12px">
                  Ovu poruku ste primili jer ste korisnik Parkify aplikacije.
                </p>
              </div>
            </body>
            </html>
            """;

        public override void Dispose()
        {
            _channel?.CloseAsync().GetAwaiter().GetResult();
            _channel?.Dispose();
            base.Dispose();
        }
    }
}