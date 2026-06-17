using Microsoft.EntityFrameworkCore;
using parkify.Model.Exceptions;

namespace parkify.Service.Services
{
    internal static class ReservationLifecycleCoordinator
    {
        public static async Task ReserveSpotAsync(
            Database.ParkifyContext context,
            int parkingZoneId,
            int parkingSpotId,
            DateTime nowUtc)
        {
            var parkingSpot = await context.ParkingSpots.FindAsync(parkingSpotId);
            if (parkingSpot == null)
            {
                throw new UserException("Parking mjesto nije pronađeno.");
            }

            if (!parkingSpot.IsAvailable)
            {
                return;
            }

            parkingSpot.IsAvailable = false;
            parkingSpot.Modified = nowUtc;

            var parkingZone = await context.ParkingZones.FindAsync(parkingZoneId);
            if (parkingZone != null && parkingZone.AvailableSpots > 0)
            {
                parkingZone.AvailableSpots -= 1;
            }
        }

        public static async Task ReleaseSpotAsync(
            Database.ParkifyContext context,
            int parkingZoneId,
            int parkingSpotId,
            DateTime nowUtc)
        {
            var parkingSpot = await context.ParkingSpots.FindAsync(parkingSpotId);
            if (parkingSpot == null || parkingSpot.IsAvailable)
            {
                return;
            }

            parkingSpot.IsAvailable = true;
            parkingSpot.Modified = nowUtc;

            var parkingZone = await context.ParkingZones.FindAsync(parkingZoneId);
            if (parkingZone != null)
            {
                parkingZone.AvailableSpots += 1;
            }
        }

        public static async Task ReleaseSpotBatchAsync(
            Database.ParkifyContext context,
            Database.Reservation reservation,
            IReadOnlyDictionary<int, Database.ParkingSpot> spotsById,
            DateTime nowUtc)
        {
            if (!spotsById.TryGetValue(reservation.ParkingSpotId, out var spot) || spot.IsAvailable)
            {
                return;
            }

            spot.IsAvailable = true;
            spot.Modified = nowUtc;

            var parkingZone = await context.ParkingZones.FindAsync(reservation.ParkingZoneId);
            if (parkingZone != null)
            {
                parkingZone.AvailableSpots += 1;
            }
        }

        public static DateTime NormalizeToUtc(DateTime value)
        {
            if (value.Kind == DateTimeKind.Utc)
            {
                return value;
            }

            if (value.Kind == DateTimeKind.Unspecified)
            {
                return DateTime.SpecifyKind(value, DateTimeKind.Utc);
            }

            return value.ToUniversalTime();
        }
    }
}
