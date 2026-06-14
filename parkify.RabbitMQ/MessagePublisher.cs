using parkify.RabbitMQ.Models;
using parkify.RabbitMQ.Settings;
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

        public MessagePublisher(RabbitMQConnection connection, RabbitMQSettings settings)
        {
            _connection = connection;
            _settings = settings;
        }

        public async Task PublishNotificationAsync(NotificationMessage message, CancellationToken cancellationToken = default)
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
    }
}
