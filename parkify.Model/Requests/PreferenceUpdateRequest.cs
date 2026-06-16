using System.ComponentModel.DataAnnotations;

namespace parkify.Model.Requests
{
    public class PreferenceUpdateRequest
    {
        public bool? PrefersNearby { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "PreferredCityId mora biti veći od 0.")]
        public int? PreferredCityId { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "FavoriteParkingZoneId mora biti veći od 0.")]
        public int? FavoriteParkingZoneId { get; set; }
        public bool? NotifyAboutOffers { get; set; }
    }
}
