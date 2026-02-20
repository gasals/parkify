namespace parkify.Service.Database
{
    public class Preference
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public bool PrefersCovered { get; set; } = false;
        public bool PrefersNearby { get; set; } = true;
        public int? PreferredCityId { get; set; }
        public int? FavoriteParkingZoneId { get; set; }
        public bool NotifyAboutOffers { get; set; } = true;
        public DateTime Created { get; set; } = DateTime.UtcNow;
        public DateTime? Modified { get; set; }

    }
}