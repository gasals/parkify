using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace parkify.Model.Requests
{
    public class ReservationInsertRequest : IValidatableObject
    {
        [JsonIgnore]
        public int UserId { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "ParkingZoneId mora biti veći od 0.")]
        public int ParkingZoneId { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "ParkingSpotId mora biti veći od 0.")]
        public int ParkingSpotId { get; set; }

        [Required(ErrorMessage = "Registracija vozila je obavezna.")]
        [StringLength(50, MinimumLength = 1, ErrorMessage = "Registracija vozila mora imati 1-50 znakova.")]
        public string VehicleLicensePlate { get; set; }

        [Required(ErrorMessage = "Vrijeme početka rezervacije je obavezno.")]
        public DateTime ReservationStart { get; set; }

        [Required(ErrorMessage = "Vrijeme završetka rezervacije je obavezno.")]
        public DateTime ReservationEnd { get; set; }
        public bool RequiresDisabledSpot { get; set; } = false;

        public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
        {
            if (ReservationEnd <= ReservationStart)
            {
                yield return new ValidationResult(
                    "Vrijeme završetka rezervacije mora biti nakon vremena početka.",
                    new[] { nameof(ReservationEnd) });
            }
        }
    }
}
