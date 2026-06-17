using System.ComponentModel.DataAnnotations;

namespace parkify.Model.Requests
{
    public class PreferenceUpdateRequest
    {
        public bool? PrefersNearby { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "PreferredCityId mora biti veći od 0.")]
        public int? PreferredCityId { get; set; }

        [Range(0, int.MaxValue, ErrorMessage = "FavoriteParkingZoneId ne može biti negativan.")]
        public int? FavoriteParkingZoneId { get; set; }
        public bool? NotifyAboutOffers { get; set; }
    }
}
