using System.ComponentModel.DataAnnotations;

namespace parkify.Model.Requests
{
    public class CityUpdateRequest
    {
        [StringLength(80, MinimumLength = 2, ErrorMessage = "Naziv grada mora imati 2-80 znakova.")]
        public string? Name { get; set; }

        [Range(-90, 90, ErrorMessage = "Latitude mora biti u rasponu od -90 do 90.")]
        public double? Latitude { get; set; }

        [Range(-180, 180, ErrorMessage = "Longitude mora biti u rasponu od -180 do 180.")]
        public double? Longitude { get; set; }

        [StringLength(80, ErrorMessage = "Country ne smije imati više od 80 znakova.")]
        public string? Country { get; set; }
    }
}