namespace parkify.Model.Requests
{
    using parkify.Model.Models;

    public class VehicleInsertRequest
    {
        public int UserId { get; set; }
        public string LicensePlate { get; set; } = string.Empty;
        public VehicleCategory Category { get; set; } = VehicleCategory.B;
        public string Model { get; set; } = string.Empty;
    }
}