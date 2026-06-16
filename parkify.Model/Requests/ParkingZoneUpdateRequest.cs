using System.ComponentModel.DataAnnotations;

namespace parkify.Model.Requests
{
    public class ParkingZoneUpdateRequest
    {
        [StringLength(100, MinimumLength = 2, ErrorMessage = "Naziv zone mora imati 2-100 znakova.")]
        public string? Name { get; set; }

        [StringLength(500, ErrorMessage = "Opis ne smije imati više od 500 znakova.")]
        public string? Description { get; set; }

        [StringLength(200, MinimumLength = 5, ErrorMessage = "Adresa mora imati 5-200 znakova.")]
        public string? Address { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "CityId mora biti veći od 0.")]
        public int? CityId { get; set; }

        [Range(-90, 90, ErrorMessage = "Latitude mora biti u rasponu od -90 do 90.")]
        public double? Latitude { get; set; }

        [Range(-180, 180, ErrorMessage = "Longitude mora biti u rasponu od -180 do 180.")]
        public double? Longitude { get; set; }

        [Range(0, int.MaxValue, ErrorMessage = "TotalSpots ne može biti negativan.")]
        public int? TotalSpots { get; set; }

        [Range(0, int.MaxValue, ErrorMessage = "DisabledSpots ne može biti negativan.")]
        public int? DisabledSpots { get; set; }

        [Range(0, int.MaxValue, ErrorMessage = "AvailableSpots ne može biti negativan.")]
        public int? AvailableSpots { get; set; }

        [Range(typeof(decimal), "0.01", "999.00", ErrorMessage = "Cijena po satu mora biti između 0.01 i 999.00.")]
        public decimal? PricePerHour { get; set; }

        [Range(typeof(decimal), "0.01", "9999.00", ErrorMessage = "Dnevna cijena mora biti između 0.01 i 9999.00.")]
        public decimal? DailyRate { get; set; }
        public bool? IsActive { get; set; }
    }
}