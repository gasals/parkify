namespace parkify.Model.Requests
{
    public class PreferenceUpdateRequest
    {
        public bool? PrefersCovered { get; set; }
        public bool? PrefersNearby { get; set; }
        public string? PreferredCity { get; set; }
        public int? FavoriteParkingZoneId { get; set; }
        public bool? NotifyAboutOffers { get; set; }
    }
}
