using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using parkify.Model.Exceptions;
using parkify.Model.Models;
using parkify.Model.Requests;
using parkify.Model.SearchObject;
using parkify.Service.Interfaces;

namespace parkify.Service.Services
{
    public class ParkingZoneService
        : BaseCRUDService<ParkingZone, ParkingZoneSearch, Database.ParkingZone, ParkingZoneInsertRequest, ParkingZoneUpdateRequest>,
          IParkingZoneService
    {
        private readonly IMemoryCache _memoryCache;

        public ParkingZoneService(Database.ParkifyContext context, IMapper mapper, IMemoryCache memoryCache)
            : base(context, mapper)
        {
            _memoryCache = memoryCache;
        }

        public override IQueryable<Database.ParkingZone> AddFilter(ParkingZoneSearch search, IQueryable<Database.ParkingZone> query)
        {
            query = base.AddFilter(search, query);

            if (!string.IsNullOrWhiteSpace(search?.Name))
            {
                query = query.Where(x => x.Name.Contains(search.Name));
            }

            if (search?.CityId.HasValue == true)
            {
                query = query.Where(x => x.CityId == search.CityId);
            }

            if (search?.IncludeSpots == true)
            {
                query = query.Include(x => x.Spots);
            }

            return query;
        }

        public async Task<List<ParkingZone>> GetRecommendations(int userId, int count = 5)
        {
            var recommendations = await GetRecommendationsWithExplanation(userId, count);
            return recommendations
                .Select(x => x.Zone)
                .ToList();
        }

        public async Task<List<ParkingZoneRecommendation>> GetRecommendationsWithExplanation(int userId, int count = 5)
        {
            var take = Math.Clamp(count, 1, 20);

            var zones = await _memoryCache.GetOrCreateAsync("parking-zones-active-v1", async entry =>
            {
                entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(2);
                return await Context.ParkingZones
                    .AsNoTracking()
                    .Where(x => x.IsActive)
                    .ToListAsync();
            }) ?? new List<Database.ParkingZone>();

            if (!zones.Any())
            {
                return new List<ParkingZoneRecommendation>();
            }

            var preference = await Context.Preferences
                .AsNoTracking()
                .FirstOrDefaultAsync(x => x.UserId == userId);

            var zoneMetrics = await Context.ParkingZones
                .AsNoTracking()
                .Where(x => x.IsActive)
                .Select(x => new
                {
                    x.Id,
                    ReservationCount = Context.Reservations.Count(r => r.UserId == userId && r.ParkingZoneId == x.Id),
                    UserRating = Context.Reviews
                        .Where(r => r.UserId == userId && r.ParkingZoneId == x.Id)
                        .Select(r => (int?)r.Rating)
                        .Max() ?? 0,
                    AverageRating = Math.Round(
                        Context.Reviews
                            .Where(r => r.ParkingZoneId == x.Id)
                            .Select(r => (double?)r.Rating)
                            .Average() ?? 0,
                        2)
                })
                .ToDictionaryAsync(x => x.Id);

            var lastReservationZoneId = await Context.Reservations
                .AsNoTracking()
                .Where(x => x.UserId == userId)
                .OrderByDescending(x => x.ReservationStart)
                .Select(x => (int?)x.ParkingZoneId)
                .FirstOrDefaultAsync();

            var referenceZone = zones.FirstOrDefault(x => x.Id == preference?.FavoriteParkingZoneId)
                ?? zones.FirstOrDefault(x => x.Id == lastReservationZoneId);

            var rankedZones = zones
                .Select(zone =>
                {
                    var mappedZone = Mapper.Map<ParkingZone>(zone);
                    var metrics = zoneMetrics.TryGetValue(zone.Id, out var metric)
                        ? metric
                        : null;

                    mappedZone.AverageRating = metrics?.AverageRating ?? 0;

                    var breakdown = CalculateRecommendationBreakdown(
                        zone,
                        preference,
                        referenceZone,
                        metrics?.ReservationCount ?? 0,
                        metrics?.UserRating ?? 0,
                        mappedZone.AverageRating);

                    return new ZoneRecommendationResult(mappedZone, breakdown.Score, breakdown.Reasons);
                })
                .OrderByDescending(x => x.Score)
                .ThenByDescending(x => x.Zone.AverageRating)
                .ThenByDescending(x => x.Zone.AvailableSpots)
                .Take(take)
                .Select(x => new ParkingZoneRecommendation
                {
                    Zone = x.Zone,
                    Score = Math.Round(x.Score, 2),
                    Reasons = x.Reasons
                })
                .ToList();

            return rankedZones;
        }

        public ParkingZone Delete(int id)
        {
            var entity = Context.ParkingZones
                .Include(x => x.Spots)
                .FirstOrDefault(x => x.Id == id);

            if (entity == null)
            {
                throw new UserException("Zona sa proslijeđenim ID-em ne postoji.");
            }

            if (entity.Spots.Any())
            {
                throw new UserException("Zona se ne može obrisati dok sadrži parking mjesta. Prvo obrišite sva mjesta ili je deaktivirajte.");
            }

            var hasHistory = Context.Reservations.Any(x => x.ParkingZoneId == id)
                || Context.Reviews.Any(x => x.ParkingZoneId == id)
                || Context.Notifications.Any(x => x.ParkingZoneId == id)
                || Context.Preferences.Any(x => x.FavoriteParkingZoneId == id);

            if (hasHistory)
            {
                throw new UserException("Zona se ne može obrisati jer ima povezane rezervacije, recenzije, notifikacije ili preferencije. Deaktivirajte je umjesto brisanja.");
            }

            Context.ParkingZones.Remove(entity);
            Context.SaveChanges();

            return Mapper.Map<ParkingZone>(entity);
        }

        private RecommendationBreakdown CalculateRecommendationBreakdown(
            Database.ParkingZone zone,
            Database.Preference? preference,
            Database.ParkingZone? referenceZone,
            int reservationCount,
            int userRating,
            double averageRating)
        {
            var score = 0d;
            var reasons = new List<string>();

            if (preference?.FavoriteParkingZoneId == zone.Id)
            {
                score += 90;
                reasons.Add("Zona je vaš favorit.");
            }

            if (preference?.PreferredCityId == zone.CityId)
            {
                score += 35;
                reasons.Add("Zona je u vašem preferiranom gradu.");
            }

            var historyScore = Math.Min(36, reservationCount * 12);
            if (historyScore > 0)
            {
                score += historyScore;
                reasons.Add($"Ranije ste koristili ovu zonu {reservationCount} put(a).");
            }

            if (averageRating > 0)
            {
                var ratingScore = averageRating * 6;
                score += ratingScore;
                reasons.Add($"Zona ima dobru prosječnu ocjenu ({averageRating:0.##}).");
            }

            if (userRating > 0)
            {
                var userRatingScore = userRating * 5;
                score += userRatingScore;
                reasons.Add($"Ranije ste ovoj zoni dali ocjenu {userRating}.");
            }

            if (zone.TotalSpots > 0)
            {
                var availabilityScore = ((double)zone.AvailableSpots / zone.TotalSpots) * 10;
                score += availabilityScore;

                if (zone.AvailableSpots > 0)
                {
                    reasons.Add($"Trenutno je dostupno {zone.AvailableSpots} od {zone.TotalSpots} mjesta.");
                }
            }

            if (zone.PricePerHour <= 0)
            {
                score += 5;
                reasons.Add("Zona ima besplatno parkiranje po satu.");
            }
            else
            {
                var priceScore = Math.Max(0, 5 - ((double)zone.PricePerHour / 2));
                score += priceScore;

                if (priceScore > 0)
                {
                    reasons.Add($"Cijena po satu je povoljna ({zone.PricePerHour:0.##}).");
                }
            }

            if (preference?.PrefersNearby == true && referenceZone != null)
            {
                var distanceKm = CalculateDistanceInKilometers(
                    referenceZone.Latitude,
                    referenceZone.Longitude,
                    zone.Latitude,
                    zone.Longitude);

                var nearbyScore = Math.Max(0, 15 - distanceKm);
                score += nearbyScore;

                reasons.Add($"Udaljenost od vaše referentne zone je oko {distanceKm:0.##} km.");
            }

            if (!reasons.Any())
            {
                reasons.Add("Preporuka je formirana na osnovu opće popularnosti i dostupnosti.");
            }

            return new RecommendationBreakdown(score, reasons);
        }

        private static double CalculateDistanceInKilometers(
            double latitude1,
            double longitude1,
            double latitude2,
            double longitude2)
        {
            const double earthRadiusKm = 6371;
            var dLat = DegreesToRadians(latitude2 - latitude1);
            var dLon = DegreesToRadians(longitude2 - longitude1);

            var lat1 = DegreesToRadians(latitude1);
            var lat2 = DegreesToRadians(latitude2);

            var a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
                    Math.Sin(dLon / 2) * Math.Sin(dLon / 2) *
                    Math.Cos(lat1) * Math.Cos(lat2);
            var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
            return earthRadiusKm * c;
        }

        private static double DegreesToRadians(double degrees)
        {
            return degrees * (Math.PI / 180);
        }

        private sealed record RecommendationBreakdown(double Score, List<string> Reasons);

        private sealed record ZoneRecommendationResult(ParkingZone Zone, double Score, List<string> Reasons);
    }
}