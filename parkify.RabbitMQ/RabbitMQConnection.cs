using parkify.RabbitMQ.Settings;
using Microsoft.Extensions.Logging;
using RabbitMQ.Client;
using RabbitMQ.Client.Exceptions;
using System.Collections.Generic;

namespace parkify.RabbitMQ
{
    public class RabbitMQConnection : IDisposable
    {
        private readonly RabbitMQSettings _settings;
        private readonly ILogger<RabbitMQConnection> _logger;
        private IConnection? _connection;
        private bool _disposed;

        public RabbitMQConnection(RabbitMQSettings settings, ILogger<RabbitMQConnection> logger)
        {
            _settings = settings;
            _logger = logger;
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

            try
            {
                return await CreateChannelCoreAsync(connection, declareDeadLetterArguments: true);
            }
            catch (OperationInterruptedException ex) when (IsQueueArgumentMismatch(ex))
            {
                _logger.LogWarning(
                    ex,
                    "Queue {Queue} already exists with different arguments. Falling back to declaration without dead-letter arguments.",
                    _settings.NotificationQueue);

                return await CreateChannelCoreAsync(connection, declareDeadLetterArguments: false);
            }
        }

        private async Task<IChannel> CreateChannelCoreAsync(IConnection connection, bool declareDeadLetterArguments)
        {
            var channel = await connection.CreateChannelAsync();

            await channel.ExchangeDeclareAsync(
                exchange: _settings.ExchangeName,
                type: ExchangeType.Direct,
                durable: true,
                autoDelete: false);

            var queueArguments = declareDeadLetterArguments
                ? new Dictionary<string, object?>
                {
                    ["x-dead-letter-exchange"] = _settings.ExchangeName,
                    ["x-dead-letter-routing-key"] = _settings.NotificationDeadLetterQueue
                }
                : null;

            await channel.QueueDeclareAsync(
                queue: _settings.NotificationQueue,
                durable: true,
                exclusive: false,
                autoDelete: false,
                arguments: queueArguments);

            await channel.QueueBindAsync(
                queue: _settings.NotificationQueue,
                exchange: _settings.ExchangeName,
                routingKey: _settings.NotificationQueue);

            await channel.QueueDeclareAsync(
                queue: _settings.NotificationDeadLetterQueue,
                durable: true,
                exclusive: false,
                autoDelete: false);

            await channel.QueueBindAsync(
                queue: _settings.NotificationDeadLetterQueue,
                exchange: _settings.ExchangeName,
                routingKey: _settings.NotificationDeadLetterQueue);

            return channel;
        }

        private bool IsQueueArgumentMismatch(OperationInterruptedException ex)
        {
            var reason = ex.ShutdownReason;
            if (reason == null || reason.ReplyCode != 406)
            {
                return false;
            }

            return reason.ReplyText.Contains("inequivalent arg", StringComparison.OrdinalIgnoreCase)
                && reason.ReplyText.Contains(_settings.NotificationQueue, StringComparison.OrdinalIgnoreCase);
        }

        public void Dispose()
        {
            if (!_disposed)
            {
                _connection?.Dispose();
                _disposed = true;
            }
        }
    }
}
