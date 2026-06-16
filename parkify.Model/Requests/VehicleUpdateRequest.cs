namespace parkify.Model.Requests
{
    using parkify.Model.Models;
    using System.ComponentModel.DataAnnotations;

    public class VehicleUpdateRequest
    {
            [StringLength(8, MinimumLength = 4, ErrorMessage = "Registracija mora imati 4-8 znakova.")]
            [RegularExpression("^[A-Za-z0-9\\-\\s]+$", ErrorMessage = "Registracija smije sadržavati samo slova, brojeve, razmak i crticu.")]
        public string? LicensePlate { get; set; }

            [EnumDataType(typeof(VehicleCategory), ErrorMessage = "Unesena kategorija vozila nije validna.")]
        public VehicleCategory? Category { get; set; }

            [StringLength(50, MinimumLength = 2, ErrorMessage = "Model vozila mora imati 2-50 znakova.")]
            [RegularExpression("^[A-Za-z0-9À-žA-Ža-ž\\s\\-\\.]+$", ErrorMessage = "Model vozila smije sadržavati slova, brojeve, razmak, crticu i tačku.")]
        public string? Model { get; set; }
    }
}