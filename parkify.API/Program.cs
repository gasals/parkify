using Mapster;
using Microsoft.EntityFrameworkCore;
using parkify.Service.Database;
using parkify.Service.Interfaces;
using parkify.Service.Services;
using parkify.API.Filters;
using Microsoft.AspNetCore.Authentication;
using parkify.API.Authentication;

var builder = WebApplication.CreateBuilder(args);

// ==================== DATABASE ====================
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
builder.Services.AddDbContext<ParkifyContext>(options =>
    options.UseSqlServer(connectionString)
           .EnableDetailedErrors()
           .EnableSensitiveDataLogging());

// ==================== MAPSTER ====================
builder.Services.AddMapster();

// ==================== SERVICES ====================
builder.Services.AddTransient<IUserService, UserService>();
builder.Services.AddTransient<IParkingZoneService, ParkingZoneService>();
builder.Services.AddTransient<IParkingSpotService, ParkingSpotService>();

// ==================== CONTROLLERS ====================
builder.Services.AddControllers(x =>
{
    x.Filters.Add<ExceptionFilter>();
});

// ==================== SWAGGER ====================
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.AddSecurityDefinition("basicAuth", new Microsoft.OpenApi.Models.OpenApiSecurityScheme()
    {
        Type = Microsoft.OpenApi.Models.SecuritySchemeType.Http,
        Scheme = "basic"
    });

    c.AddSecurityRequirement(new Microsoft.OpenApi.Models.OpenApiSecurityRequirement()
    {
        {
            new Microsoft.OpenApi.Models.OpenApiSecurityScheme
            {
                Reference = new Microsoft.OpenApi.Models.OpenApiReference
                {
                    Type = Microsoft.OpenApi.Models.ReferenceType.SecurityScheme,
                    Id = "basicAuth"
                }
            },
            new string[]{}
        }
    });
});

// ==================== CORS ====================
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

// ==================== AUTHENTICATION ====================
builder.Services.AddAuthentication("BasicAuthentication")
    .AddScheme<AuthenticationSchemeOptions, BasicAuthenticationHandler>("BasicAuthentication", null);

var app = builder.Build();

// ==================== PIPELINE ====================
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

//app.UseHttpsRedirection();
app.UseCors("AllowAll");
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

// ==================== AUTO MIGRATE ====================
using (var scope = app.Services.CreateScope())
{
    var context = scope.ServiceProvider.GetRequiredService<ParkifyContext>();
    context.Database.Migrate();
}

app.Run("http://0.0.0.0:5050");