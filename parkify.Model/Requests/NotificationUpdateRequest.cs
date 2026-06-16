using System.ComponentModel.DataAnnotations;

namespace parkify.Model.Requests
{
    public class NotificationUpdateRequest
    {
        [Required(ErrorMessage = "Naslov notifikacije je obavezan.")]
        [StringLength(120, MinimumLength = 3, ErrorMessage = "Naslov notifikacije mora imati 3-120 znakova.")]
        public string Title { get; set; }

        [Required(ErrorMessage = "Poruka notifikacije je obavezna.")]
        [StringLength(1000, MinimumLength = 5, ErrorMessage = "Poruka notifikacije mora imati 5-1000 znakova.")]
        public string Message { get; set; }

        [Range(1, 10, ErrorMessage = "Tip notifikacije mora biti između 1 i 10.")]
        public int Type { get; set; }
        public bool IsRead { get; set; }
        public DateTime? ReadDate { get; set; }
    }
}
