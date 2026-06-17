namespace parkify.Model.Requests
{
    using parkify.Model.Models;
    using System.ComponentModel.DataAnnotations;
    using System.Text.Json.Serialization;

    public class VehicleInsertRequest
    {
            [JsonIgnore]
        public int UserId { get; set; }

            [Required(ErrorMessage = "Registracija vozila je obavezna.")]
            [StringLength(50, MinimumLength = 1, ErrorMessage = "Registracija mora imati 1-50 znakova.")]
        public string LicensePlate { get; set; } = string.Empty;

            [EnumDataType(typeof(VehicleCategory), ErrorMessage = "Unesena kategorija vozila nije validna.")]
        public VehicleCategory Category { get; set; } = VehicleCategory.B;

            [Required(ErrorMessage = "Model vozila je obavezan.")]
            [StringLength(50, MinimumLength = 2, ErrorMessage = "Model vozila mora imati 2-50 znakova.")]
            [RegularExpression("^[A-Za-z0-9À-žA-Ža-ž\\s\\-\\.]+$", ErrorMessage = "Model vozila smije sadržavati slova, brojeve, razmak, crticu i tačku.")]
        public string Model { get; set; } = string.Empty;
    }
}