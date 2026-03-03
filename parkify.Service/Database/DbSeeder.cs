using System.Security.Cryptography;
using System.Text;

namespace parkify.Service.Database
{
    public static class DbSeeder
    {
        public static void Seed(ParkifyContext context)
        {
            if (context.Cities.Any())
                return;

            var sarajevo = new City
            {
                Name = "Sarajevo",
                Latitude = 43.8563,
                Longitude = 18.4131
            };

            var mostar = new City
            {
                Name = "Mostar",
                Latitude = 43.3438,
                Longitude = 17.8078
            };

            context.Cities.AddRange(sarajevo, mostar);
            context.SaveChanges();

            var adminSalt = GenerateSalt();
            var adminHash = GenerateHash(adminSalt, "Test123!");

            var userSalt = GenerateSalt();
            var userHash = GenerateHash(userSalt, "Test123!");

            var admin = new User
            {
                Username = "admin",
                Email = "parkify.rs2@gmail.com",
                FirstName = "Admin",
                LastName = "Admin",
                PasswordSalt = adminSalt,
                PasswordHash = adminHash,
                IsAdmin = true
            };

            var user1 = new User
            {
                Username = "user",
                Email = "gasal.sejad@gmail.com",
                FirstName = "User",
                LastName = "User",
                PasswordSalt = userSalt,
                PasswordHash = userHash,
                IsAdmin = false,
                City = "Mostar"
            };

            context.Users.AddRange(admin, user1);
            context.SaveChanges();

            var zonaSarajevo = new ParkingZone
            {
                Name = "Centar Parking",
                Description = "Parking zona u centru Sarajeva",
                Address = "Zelenih beretki 1",
                CityId = sarajevo.Id,
                Latitude = 43.8570,
                Longitude = 18.4125,
                TotalSpots = 4,
                DisabledSpots = 2,
                AvailableSpots = 4,
                PricePerHour = 2.50m,
                DailyRate = 12.00m
            };

            var zonaMostar = new ParkingZone
            {
                Name = "Stari Most Parking",
                Description = "Parking zona blizu Starog Mosta",
                Address = "Kujundžiluk bb",
                CityId = mostar.Id,
                Latitude = 43.3430,
                Longitude = 17.8080,
                TotalSpots = 8,
                DisabledSpots = 1,
                AvailableSpots = 8,
                PricePerHour = 2.00m,
                DailyRate = 10.00m
            };

            context.ParkingZones.AddRange(zonaSarajevo, zonaMostar);
            context.SaveChanges();

            var spots = new List<ParkingSpot>();

            for (int i = 1; i <= 4; i++)
            {
                spots.Add(new ParkingSpot
                {
                    SpotCode = $"Z{zonaSarajevo.Id}/1-{i}",
                    ParkingZoneId = zonaSarajevo.Id,
                    Type = i <= 2 ? ParkingSpotType.Disabled : ParkingSpotType.Standard,
                    RowNumber = 1,
                    ColumnNumber = i
                });
            }

            for (int i = 1; i <= 8; i++)
            {
                int rowNumber = (i - 1) / 4 + 1;
                int columnNumber = (i - 1) % 4 + 1;

                spots.Add(new ParkingSpot
                {
                    SpotCode = $"Z{zonaMostar.Id}/{rowNumber}-{columnNumber}",
                    ParkingZoneId = zonaMostar.Id,
                    Type = i == 1 ? ParkingSpotType.Disabled : ParkingSpotType.Standard,
                    RowNumber = rowNumber,
                    ColumnNumber = columnNumber
                });
            }

            context.ParkingSpots.AddRange(spots);
            context.SaveChanges();

            var vehicle = new Vehicle
            {
                UserId = user1.Id,
                LicensePlate = "E12-K-345",
                Category = "Sedan",
                Model = "VW Golf"
            };

            context.Vehicles.Add(vehicle);
            context.SaveChanges();

            var wallet = new Wallet
            {
                UserId = user1.Id,
                Balance = 50.00m
            };

            context.Wallets.Add(wallet);
            context.SaveChanges();

            var preference = new Preference
            {
                UserId = user1.Id,
                PreferredCityId = mostar.Id,
                NotifyAboutOffers = true
            };

            context.Preferences.Add(preference);
            context.SaveChanges();
        }

        public static string GenerateSalt()
        {
            var bytes = RandomNumberGenerator.GetBytes(16);
            return Convert.ToBase64String(bytes);
        }

        public static string GenerateHash(string salt, string password)
        {
            var saltBytes = Convert.FromBase64String(salt);
            var passwordBytes = Encoding.Unicode.GetBytes(password);

            var combined = new byte[saltBytes.Length + passwordBytes.Length];
            Buffer.BlockCopy(saltBytes, 0, combined, 0, saltBytes.Length);
            Buffer.BlockCopy(passwordBytes, 0, combined, saltBytes.Length, passwordBytes.Length);

            using var algorithm = SHA1.Create();
            return Convert.ToBase64String(algorithm.ComputeHash(combined));
        }
    }
}