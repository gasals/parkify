using System.ComponentModel.DataAnnotations;

namespace parkify.Model.Requests
{
    public class VehicleInsertRequest
    {
        public int UserId { get; set; }
        public string LicensePlate { get; set; } = string.Empty;
        public string Category { get; set; } = string.Empty;
        public string Model { get; set; } = string.Empty;
    }
}