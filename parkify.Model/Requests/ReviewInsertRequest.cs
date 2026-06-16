using System.ComponentModel.DataAnnotations;

namespace parkify.Model.Requests
{
    public class ReviewInsertRequest
    {
        [Range(1, int.MaxValue, ErrorMessage = "ParkingZoneId mora biti veći od 0.")]
        public int ParkingZoneId { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "UserId mora biti veći od 0.")]
        public int UserId { get; set; }

        [Range(1, 5, ErrorMessage = "Ocjena mora biti između 1 i 5.")]
        public int Rating { get; set; }

        [StringLength(500, MinimumLength = 10, ErrorMessage = "Recenzija mora imati 10-500 znakova.")]
        public string? ReviewText { get; set; }
    }
}
