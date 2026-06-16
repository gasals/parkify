using System.ComponentModel.DataAnnotations;

namespace parkify.Model.Requests
{
    public class UserUpdateRequest : IValidatableObject
    {
        [EmailAddress(ErrorMessage = "Unesite validan email u formatu: korisnik@domena.tld.")]
        [StringLength(100, ErrorMessage = "Email ne smije imati više od 100 znakova.")]
        public string? Email { get; set; }

        [StringLength(50, MinimumLength = 2, ErrorMessage = "Ime mora imati 2-50 znakova.")]
        [RegularExpression("^[A-Za-zÀ-žA-Ža-ž\\s'\\-]+$", ErrorMessage = "Ime smije sadržavati samo slova, razmak, apostrof i crticu.")]
        public string? FirstName { get; set; }

        [StringLength(50, MinimumLength = 2, ErrorMessage = "Prezime mora imati 2-50 znakova.")]
        [RegularExpression("^[A-Za-zÀ-žA-Ža-ž\\s'\\-]+$", ErrorMessage = "Prezime smije sadržavati samo slova, razmak, apostrof i crticu.")]
        public string? LastName { get; set; }

        [StringLength(200, ErrorMessage = "Adresa ne smije imati više od 200 znakova.")]
        public string? Address { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "CityId mora biti veći od 0.")]
        public int? CityId { get; set; }

        [StringLength(128, MinimumLength = 1, ErrorMessage = "Trenutna lozinka mora imati do 128 znakova.")]
        public string? CurrentPassword { get; set; }

        [StringLength(128, MinimumLength = 8, ErrorMessage = "Nova lozinka mora imati najmanje 8 znakova.")]
        [RegularExpression("^(?=.*[A-Z])(?=.*\\d)(?=.*[^A-Za-z0-9]).{8,}$", ErrorMessage = "Nova lozinka mora sadržavati najmanje jedno veliko slovo, jedan broj i jedan poseban znak.")]
        public string? Password { get; set; }
        public string? PasswordConfirm { get; set; }
        public bool? IsActive { get; set; }

        public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
        {
            if (!string.IsNullOrWhiteSpace(Password))
            {
                if (string.IsNullOrWhiteSpace(PasswordConfirm))
                {
                    yield return new ValidationResult(
                        "Potvrda lozinke je obavezna kada se unosi nova lozinka.",
                        new[] { nameof(PasswordConfirm) });
                }
                else if (!string.Equals(Password, PasswordConfirm, StringComparison.Ordinal))
                {
                    yield return new ValidationResult(
                        "Lozinka i potvrda lozinke se ne podudaraju.",
                        new[] { nameof(PasswordConfirm) });
                }
            }

            if (string.IsNullOrWhiteSpace(Password) && !string.IsNullOrWhiteSpace(PasswordConfirm))
            {
                yield return new ValidationResult(
                    "Nova lozinka je obavezna kada je unesena potvrda lozinke.",
                    new[] { nameof(Password) });
            }
        }
    }
}