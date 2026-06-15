namespace parkify.Model.Models
{
    public class Vehicle
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string LicensePlate { get; set; } = string.Empty;
        public VehicleCategory Category { get; set; } = VehicleCategory.B;
        public string Model { get; set; } = string.Empty;
        public DateTime Created { get; set; } = DateTime.UtcNow;
        public DateTime? Modified { get; set; }

    }

    public enum VehicleCategory
    {
        AM = 1,
        A1 = 2,
        A2 = 3,
        A = 4,
        B = 5,
        BE = 6,
        C1 = 7,
        C1E = 8,
        C = 9,
        CE = 10,
        D1 = 11,
        D1E = 12,
        D = 13,
        DE = 14,
        F = 15,
        G = 16,
        H = 17
    }
}