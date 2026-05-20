using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using Microsoft.Extensions.Configuration;

namespace parkify.Service.Database
{
    public class ParkifyContextFactory : IDesignTimeDbContextFactory<ParkifyContext>
    {
        public ParkifyContext CreateDbContext(string[] args)
        {
            var configurationBasePath = ResolveConfigurationBasePath();

            var configuration = new ConfigurationBuilder()
                .SetBasePath(configurationBasePath)
                .AddJsonFile("appsettings.json", optional: true)
                .AddJsonFile("appsettings.Development.json", optional: true)
                .AddEnvironmentVariables()
                .Build();

            var connectionString = configuration.GetConnectionString("DefaultConnection");
            if (string.IsNullOrWhiteSpace(connectionString))
            {
                throw new InvalidOperationException(
                    "DefaultConnection nije pronađen za design-time ParkifyContext.");
            }

            var optionsBuilder = new DbContextOptionsBuilder<ParkifyContext>();
            optionsBuilder.UseSqlServer(connectionString);

            return new ParkifyContext(optionsBuilder.Options);
        }

        private static string ResolveConfigurationBasePath()
        {
            var currentDirectory = Directory.GetCurrentDirectory();
            var candidates = new[]
            {
                Path.Combine(currentDirectory, "..", "parkify.API"),
                Path.Combine(currentDirectory, "parkify.API"),
                currentDirectory
            };

            foreach (var candidate in candidates)
            {
                if (File.Exists(Path.Combine(candidate, "appsettings.json")))
                {
                    return Path.GetFullPath(candidate);
                }
            }

            return currentDirectory;
        }
    }
}