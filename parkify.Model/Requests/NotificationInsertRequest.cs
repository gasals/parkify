using System.ComponentModel.DataAnnotations;

namespace parkify.Model.Requests
{
    public class NotificationInsertRequest
    {
        [Range(1, int.MaxValue, ErrorMessage = "UserId mora biti veći od 0.")]
        public int UserId { get; set; }

        [Required(ErrorMessage = "Naslov notifikacije je obavezan.")]
        [StringLength(120, MinimumLength = 3, ErrorMessage = "Naslov notifikacije mora imati 3-120 znakova.")]
        public string Title { get; set; } = string.Empty;

        [Required(ErrorMessage = "Poruka notifikacije je obavezna.")]
        [StringLength(1000, MinimumLength = 5, ErrorMessage = "Poruka notifikacije mora imati 5-1000 znakova.")]
        public string Message { get; set; } = string.Empty;

        [Range(1, 10, ErrorMessage = "Tip notifikacije mora biti između 1 i 10.")]
        public int Type { get; set; }

        [Range(1, 3, ErrorMessage = "Channel mora biti 1 (InApp), 2 (Email) ili 3 (Both).")]
        public int? Channel { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "ReservationId mora biti veći od 0.")]
        public int? ReservationId { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "ParkingZoneId mora biti veći od 0.")]
        public int? ParkingZoneId { get; set; }
    }
}
