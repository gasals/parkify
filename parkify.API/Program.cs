using Mapster;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using parkify.API.Filters;
using parkify.RabbitMQ;
using parkify.Service.Database;
using parkify.Service.Interfaces;
using parkify.Service.Services;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
builder.Services.AddDbContext<ParkifyContext>(options =>
    options.UseSqlServer(connectionString)
           .EnableDetailedErrors()
           .EnableSensitiveDataLogging());

builder.Services.AddMapster();

builder.Services.AddTransient<IUserService, UserService>();
builder.Services.AddTransient<IParkingZoneService, ParkingZoneService>();
builder.Services.AddTransient<IParkingSpotService, ParkingSpotService>();
builder.Services.AddTransient<INotificationService, NotificationService>();
builder.Services.AddTransient<IReservationService, ReservationService>();
builder.Services.AddTransient<IPaymentService, PaymentService>();
builder.Services.AddTransient<IPreferenceService, PreferenceService>();
builder.Services.AddTransient<IReviewService, ReviewService>();
builder.Services.AddTransient<ICityService, CityService>();
builder.Services.AddTransient<IVehicleService, VehicleService>();
builder.Services.AddTransient<IWalletService, WalletService>();
builder.Services.AddTransient<IWalletTransactionService, WalletTransactionService>();

builder.Services.AddControllers(x =>
{
    x.Filters.Add<ExceptionFilter>();
});

builder.Services.AddSwaggerGen(c =>
{
    c.AddSecurityDefinition("Bearer", new Microsoft.OpenApi.Models.OpenApiSecurityScheme()
    {
        Name = "Authorization",
        Type = Microsoft.OpenApi.Models.SecuritySchemeType.ApiKey,
        Scheme = "Bearer",
        BearerFormat = "JWT",
        In = Microsoft.OpenApi.Models.ParameterLocation.Header
    });

    c.AddSecurityRequirement(new Microsoft.OpenApi.Models.OpenApiSecurityRequirement()
    {
        {
            new Microsoft.OpenApi.Models.OpenApiSecurityScheme
            {
                Reference = new Microsoft.OpenApi.Models.OpenApiReference
                {
                    Type = Microsoft.OpenApi.Models.ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            new string[] {}
        }
    });
});

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

var jwtSettings = builder.Configuration.GetSection("Jwt");
var secretKey = Encoding.ASCII.GetBytes(jwtSettings["Key"]);

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.RequireHttpsMetadata = false;
    options.SaveToken = true;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(secretKey),
        ValidateIssuer = true,
        ValidIssuer = jwtSettings["Issuer"],
        ValidateAudience = true,
        ValidAudience = jwtSettings["Audience"],
        ValidateLifetime = true,
        ClockSkew = TimeSpan.Zero
    };
});

builder.Services.AddRabbitMQ(builder.Configuration);
builder.Services.AddHostedService<NotificationConsumerService>();
builder.Services.AddHostedService<ReservationMonitorService>();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors("AllowAll");
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

using (var scope = app.Services.CreateScope())
{
    var context = scope.ServiceProvider.GetRequiredService<ParkifyContext>();
    context.Database.Migrate();
}

app.Run("http://0.0.0.0:5050");