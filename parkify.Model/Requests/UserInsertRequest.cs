using System.ComponentModel.DataAnnotations;

namespace parkify.Model.Requests
{
    public class UserInsertRequest
    {
        [Required(ErrorMessage = "Korisničko ime je obavezno.")]
        [StringLength(30, MinimumLength = 3, ErrorMessage = "Korisničko ime mora imati 3-30 znakova.")]
        [RegularExpression("^[A-Za-z0-9_.]+$", ErrorMessage = "Korisničko ime smije sadržavati samo slova, brojeve, '_' i '.'.")]
        public string Username { get; set; }

        [Required(ErrorMessage = "Email je obavezan.")]
        [EmailAddress(ErrorMessage = "Unesite validan email u formatu: korisnik@domena.tld.")]
        [StringLength(100, ErrorMessage = "Email ne smije imati više od 100 znakova.")]
        public string Email { get; set; }

        [Required(ErrorMessage = "Lozinka je obavezna.")]
        [StringLength(128, MinimumLength = 8, ErrorMessage = "Lozinka mora imati najmanje 8 znakova.")]
        [RegularExpression("^(?=.*[A-Z])(?=.*\\d)(?=.*[^A-Za-z0-9]).{8,}$", ErrorMessage = "Lozinka mora sadržavati najmanje jedno veliko slovo, jedan broj i jedan poseban znak.")]
        public string Password { get; set; }

        [Required(ErrorMessage = "Ime je obavezno.")]
        [StringLength(50, MinimumLength = 2, ErrorMessage = "Ime mora imati 2-50 znakova.")]
        [RegularExpression("^[A-Za-zÀ-žA-Ža-ž\\s'\\-]+$", ErrorMessage = "Ime smije sadržavati samo slova, razmak, apostrof i crticu.")]
        public string FirstName { get; set; }

        [Required(ErrorMessage = "Prezime je obavezno.")]
        [StringLength(50, MinimumLength = 2, ErrorMessage = "Prezime mora imati 2-50 znakova.")]
        [RegularExpression("^[A-Za-zÀ-žA-Ža-ž\\s'\\-]+$", ErrorMessage = "Prezime smije sadržavati samo slova, razmak, apostrof i crticu.")]
        public string LastName { get; set; }

        [StringLength(200, ErrorMessage = "Adresa ne smije imati više od 200 znakova.")]
        public string? Address { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "CityId mora biti veći od 0.")]
        public int? CityId { get; set; }

        [Required(ErrorMessage = "Potvrda lozinke je obavezna.")]
        [Compare(nameof(Password), ErrorMessage = "Lozinka i potvrda lozinke se ne podudaraju.")]
        public string PasswordConfirm { get; set; }
    }
}