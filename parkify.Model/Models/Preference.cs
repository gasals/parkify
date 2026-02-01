using System;

namespace parkify.Model.Models
{
    public class Preference
    {
        public int Id { get; set; }
        public string UserId { get; set; } = string.Empty;
        public bool PrefersCovered { get; set; } = false;
        public bool PrefersNearby { get; set; } = true;
        public string PreferredCity { get; set; } = string.Empty;
        public int? FavoriteParkingZoneId { get; set; }
        public bool NotifyAboutOffers { get; set; } = true;
        public DateTime CreatedDate { get; set; } = DateTime.UtcNow;

        public required User User { get; set; }
        public ParkingZone? FavoriteParkingZone { get; set; }
    }
}