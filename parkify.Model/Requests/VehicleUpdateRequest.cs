namespace parkify.Model.Requests
{
    using parkify.Model.Models;

    public class VehicleUpdateRequest
    {
        public string? LicensePlate { get; set; }
        public VehicleCategory? Category { get; set; }
        public string? Model { get; set; }
    }
}