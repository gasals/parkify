using parkify.RabbitMQ.Settings;
using RabbitMQ.Client;

namespace parkify.RabbitMQ
{
    public class RabbitMQConnection : IDisposable
    {
        private readonly RabbitMQSettings _settings;
        private IConnection? _connection;
        private bool _disposed;

        public RabbitMQConnection(RabbitMQSettings settings)
        {
            _settings = settings;
        }

        public async Task<IConnection> GetConnectionAsync()
        {
            if (_connection == null || !_connection.IsOpen)
            {
                var factory = new ConnectionFactory
                {
                    HostName = _settings.Host,
                    Port = _settings.Port,
                    UserName = _settings.Username,
                    Password = _settings.Password,
                    VirtualHost = _settings.VirtualHost,
                    AutomaticRecoveryEnabled = true,
                    NetworkRecoveryInterval = TimeSpan.FromSeconds(10)
                };
                _connection = await factory.CreateConnectionAsync();
            }
            return _connection;
        }

        public async Task<IChannel> CreateChannelAsync()
        {
            var connection = await GetConnectionAsync();
            var channel = await connection.CreateChannelAsync();

            await channel.ExchangeDeclareAsync(
                exchange: _settings.ExchangeName,
                type: ExchangeType.Direct,
                durable: true,
                autoDelete: false);

            await channel.QueueDeclareAsync(
                queue: _settings.NotificationQueue,
                durable: true,
                exclusive: false,
                autoDelete: false);

            await channel.QueueBindAsync(
                queue: _settings.NotificationQueue,
                exchange: _settings.ExchangeName,
                routingKey: _settings.NotificationQueue);

            return channel;
        }

        public void Dispose()
        {
            if (!_disposed)
            {
                _connection?.CloseAsync().GetAwaiter().GetResult();
                _connection?.Dispose();
                _disposed = true;
            }
        }
    }
}
