using Microsoft.Extensions.DependencyInjection;
using parkify.Service.Interfaces;
using parkify.Service.Services;
using Parkify.Service.Jobs;

namespace parkify.Service.Extensions
{
    public static class ServiceCollectionExtensions
    {
        public static IServiceCollection AddParkifyCoreServices(this IServiceCollection services)
        {
            services.AddTransient<IUserService, UserService>();
            services.AddTransient<IParkingZoneService, ParkingZoneService>();
            services.AddTransient<IParkingSpotService, ParkingSpotService>();
            services.AddTransient<INotificationService, NotificationService>();
            services.AddTransient<IReservationService, ReservationService>();
            services.AddTransient<IPaymentService, PaymentService>();
            services.AddTransient<IPreferenceService, PreferenceService>();
            services.AddTransient<IReviewService, ReviewService>();
            services.AddTransient<ICityService, CityService>();
            services.AddTransient<IVehicleService, VehicleService>();
            services.AddTransient<IWalletService, WalletService>();
            services.AddTransient<IWalletTransactionService, WalletTransactionService>();

            return services;
        }

        public static IServiceCollection AddParkifyHostedServices(this IServiceCollection services)
        {
            services.AddHostedService<NotificationConsumerService>();
            services.AddHostedService<ReservationMonitorService>();
            services.AddHostedService<ReservationStatusJob>();

            return services;
        }
    }
}