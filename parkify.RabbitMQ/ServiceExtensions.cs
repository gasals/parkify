using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using parkify.RabbitMQ.Settings;

namespace parkify.RabbitMQ
{
    public static class ServiceExtensions
    {
        public static IServiceCollection AddRabbitMQ(
            this IServiceCollection services,
            IConfiguration configuration)
        {
            var settings = configuration
                .GetSection("RabbitMQ")
                .Get<RabbitMQSettings>() ?? new RabbitMQSettings();

            services.AddSingleton(settings);
            services.AddSingleton<RabbitMQConnection>();
            services.AddSingleton<IMessagePublisher, MessagePublisher>();

            services.Configure<SmtpSettings>(configuration.GetSection("Smtp"));
            services.AddTransient<IEmailService, SmtpEmailService>();

            return services;
        }
    }
}
