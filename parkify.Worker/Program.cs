using Mapster;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using parkify.RabbitMQ;
using parkify.Service.Database;
using parkify.Service.Extensions;

var builder = Host.CreateApplicationBuilder(args);

builder.Configuration
    .AddJsonFile(Path.Combine(AppContext.BaseDirectory, "appsettings.json"), optional: true, reloadOnChange: false)
    .AddJsonFile(
        Path.Combine(AppContext.BaseDirectory, $"appsettings.{builder.Environment.EnvironmentName}.json"),
        optional: true,
        reloadOnChange: false)
    .AddEnvironmentVariables();

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
if (string.IsNullOrWhiteSpace(connectionString))
{
    throw new InvalidOperationException("Worker configuration is missing ConnectionStrings:DefaultConnection.");
}

builder.Services.AddDbContext<ParkifyContext>(options =>
    options.UseSqlServer(connectionString)
           .EnableDetailedErrors()
           .EnableSensitiveDataLogging());

builder.Services.AddMapster();
builder.Services.AddParkifyCoreServices();
builder.Services.AddRabbitMQ(builder.Configuration);
builder.Services.AddParkifyHostedServices();

var host = builder.Build();
await host.RunAsync();
