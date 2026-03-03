using System.Text;
using System.Text.Json;
using parkify.RabbitMQ.Models;
using parkify.RabbitMQ.Settings;
using RabbitMQ.Client;

namespace parkify.RabbitMQ
{
    public interface IMessagePublisher
    {
        void PublishNotification(NotificationMessage message);
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

        public void PublishNotification(NotificationMessage message)
        {
            PublishAsync(message).GetAwaiter().GetResult();
        }

        private async Task PublishAsync(NotificationMessage message)
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
                body: body);
        }
    }
}
