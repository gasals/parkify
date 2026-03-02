using System;

namespace parkify.Model.Models
{
    public class Vehicle
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string LicensePlate { get; set; } = string.Empty;
        public string Category { get; set; } = string.Empty;
        public string Model { get; set; } = string.Empty;
        public DateTime Created { get; set; } = DateTime.UtcNow;
        public DateTime? Modified { get; set; }

    }
}