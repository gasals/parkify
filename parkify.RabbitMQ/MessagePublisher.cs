using parkify.RabbitMQ.Models;
using parkify.RabbitMQ.Settings;
using Microsoft.Extensions.Logging;
using RabbitMQ.Client;
using System.Text;
using System.Text.Json;

namespace parkify.RabbitMQ
{
    public interface IMessagePublisher
    {
        Task PublishNotificationAsync(NotificationMessage message, CancellationToken cancellationToken = default);
    }

    public class MessagePublisher : IMessagePublisher
    {
        private readonly RabbitMQConnection _connection;
        private readonly RabbitMQSettings _settings;
        private readonly ILogger<MessagePublisher> _logger;

        public MessagePublisher(
            RabbitMQConnection connection,
            RabbitMQSettings settings,
            ILogger<MessagePublisher> logger)
        {
            _connection = connection;
            _settings = settings;
            _logger = logger;
        }

        public async Task PublishNotificationAsync(NotificationMessage message, CancellationToken cancellationToken = default)
        {
            try
            {
                using var channel = await _connection.CreateChannelAsync();

                var body = Encoding.UTF8.GetBytes(JsonSerializer.Serialize(message));

                var properties = new BasicProperties
                {
                    Persistent = true,
                    ContentType = "application/json"
                };

                await channel.BasicPublishAsync(
                    exchange: _settings.ExchangeName,
                    routingKey: _settings.NotificationQueue,
                    mandatory: false,
                    basicProperties: properties,
                    body: body,
                    cancellationToken: cancellationToken);
            }
            catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
            {
                throw;
            }
            catch (Exception ex)
            {
                _logger.LogWarning(
                    ex,
                    "Notification publish failed for user {UserId}. API flow continues without blocking.",
                    message.UserId);
            }
        }
    }
}
