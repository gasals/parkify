using MapsterMapper;
using Microsoft.EntityFrameworkCore;
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
        public ParkingZoneService(Database.ParkifyContext context, IMapper mapper)
            : base(context, mapper)
        {
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

        public List<ParkingZone> GetRecommendations(int userId, int count = 5)
        {
            var take = Math.Clamp(count, 1, 20);

            var zones = Context.ParkingZones
                .AsNoTracking()
                .Where(x => x.IsActive)
                .ToList();

            if (!zones.Any())
            {
                return new List<ParkingZone>();
            }

            var preference = Context.Preferences
                .AsNoTracking()
                .FirstOrDefault(x => x.UserId == userId);

            var userReservations = Context.Reservations
                .AsNoTracking()
                .Where(x => x.UserId == userId)
                .ToList();

            var reservationCounts = userReservations
                .GroupBy(x => x.ParkingZoneId)
                .ToDictionary(x => x.Key, x => x.Count());

            var lastReservationZoneId = userReservations
                .OrderByDescending(x => x.ReservationStart)
                .Select(x => (int?)x.ParkingZoneId)
                .FirstOrDefault();

            var userRatings = Context.Reviews
                .AsNoTracking()
                .Where(x => x.UserId == userId)
                .GroupBy(x => x.ParkingZoneId)
                .ToDictionary(x => x.Key, x => x.Max(y => y.Rating));

            var averageRatings = Context.Reviews
                .AsNoTracking()
                .GroupBy(x => x.ParkingZoneId)
                .ToDictionary(x => x.Key, x => Math.Round(x.Average(y => y.Rating), 2));

            var referenceZone = zones.FirstOrDefault(x => x.Id == preference?.FavoriteParkingZoneId)
                ?? zones.FirstOrDefault(x => x.Id == lastReservationZoneId);

            var rankedZones = zones
                .Select(zone =>
                {
                    var mappedZone = Mapper.Map<ParkingZone>(zone);
                    mappedZone.AverageRating = averageRatings.TryGetValue(zone.Id, out var avgRating)
                        ? avgRating
                        : 0;

                    var score = CalculateRecommendationScore(
                        zone,
                        preference,
                        referenceZone,
                        reservationCounts.TryGetValue(zone.Id, out var reservationCount) ? reservationCount : 0,
                        userRatings.TryGetValue(zone.Id, out var userRating) ? userRating : 0,
                        mappedZone.AverageRating);

                    return new ZoneRecommendationResult(mappedZone, score);
                })
                .OrderByDescending(x => x.Score)
                .ThenByDescending(x => x.Zone.AverageRating)
                .ThenByDescending(x => x.Zone.AvailableSpots)
                .Take(take)
                .Select(x => x.Zone)
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

        private double CalculateRecommendationScore(
            Database.ParkingZone zone,
            Database.Preference? preference,
            Database.ParkingZone? referenceZone,
            int reservationCount,
            int userRating,
            double averageRating)
        {
            var score = 0d;

            if (preference?.FavoriteParkingZoneId == zone.Id)
            {
                score += 90;
            }

            if (preference?.PreferredCityId == zone.CityId)
            {
                score += 35;
            }

            score += Math.Min(36, reservationCount * 12);
            score += averageRating * 6;
            score += userRating * 5;

            if (zone.TotalSpots > 0)
            {
                score += ((double)zone.AvailableSpots / zone.TotalSpots) * 10;
            }

            if (zone.PricePerHour <= 0)
            {
                score += 5;
            }
            else
            {
                score += Math.Max(0, 5 - ((double)zone.PricePerHour / 2));
            }

            if (preference?.PrefersNearby == true && referenceZone != null)
            {
                var distanceKm = CalculateDistanceInKilometers(
                    referenceZone.Latitude,
                    referenceZone.Longitude,
                    zone.Latitude,
                    zone.Longitude);

                score += Math.Max(0, 15 - distanceKm);
            }

            return score;
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

        private sealed record ZoneRecommendationResult(ParkingZone Zone, double Score);
    }
}