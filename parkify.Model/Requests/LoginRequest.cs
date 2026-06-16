using System.ComponentModel.DataAnnotations;

namespace parkify.Model.Requests
{
    public class LoginRequest
    {
        [Required(ErrorMessage = "Korisničko ime je obavezno.")]
        [StringLength(30, MinimumLength = 3, ErrorMessage = "Korisničko ime mora imati 3-30 znakova.")]
        public string Username { get; set; } = string.Empty;

        [Required(ErrorMessage = "Lozinka je obavezna.")]
        [StringLength(128, MinimumLength = 8, ErrorMessage = "Lozinka mora imati najmanje 8 znakova.")]
        public string Password { get; set; } = string.Empty;
    }
}