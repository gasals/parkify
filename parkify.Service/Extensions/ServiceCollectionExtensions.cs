using Microsoft.Extensions.DependencyInjection;
using parkify.Service.Interfaces;
using parkify.Service.Services;

namespace parkify.Service.Extensions
{
    public static class ServiceCollectionExtensions
    {
        public static IServiceCollection AddParkifyCoreServices(this IServiceCollection services)
        {
            services.AddScoped<IAuthTokenService, AuthTokenService>();
            services.AddScoped<IUserService, UserService>();
            services.AddScoped<IParkingZoneService, ParkingZoneService>();
            services.AddScoped<IParkingSpotService, ParkingSpotService>();
            services.AddScoped<INotificationService, NotificationService>();
            services.AddScoped<IReservationService, ReservationService>();
            services.AddScoped<IPaymentService, PaymentService>();
            services.AddScoped<IPreferenceService, PreferenceService>();
            services.AddScoped<IReviewService, ReviewService>();
            services.AddScoped<ICityService, CityService>();
            services.AddScoped<IVehicleService, VehicleService>();
            services.AddScoped<IWalletService, WalletService>();
            services.AddScoped<IWalletTransactionService, WalletTransactionService>();

            return services;
        }

        public static IServiceCollection AddParkifyHostedServices(this IServiceCollection services)
        {
            services.AddHostedService<NotificationConsumerService>();
            services.AddHostedService<ReservationMonitorService>();

            return services;
        }
    }
}