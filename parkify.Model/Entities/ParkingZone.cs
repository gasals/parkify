namespace parkify.Model.Entities
{
    public class ParkingZone
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public string Address { get; set; } = string.Empty;
        public string City { get; set; } = string.Empty;
        public double Latitude { get; set; }
        public double Longitude { get; set; }
        public int TotalSpots { get; set; }
        public int DisabledSpots { get; set; }
        public int CoveredSpots { get; set; }
        public decimal PricePerHour { get; set; }
        public decimal DailyRate { get; set; }
        public bool IsActive { get; set; } = true;
        public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedDate { get; set; }

        public ICollection<ParkingSpot> Spots { get; set; } = new List<ParkingSpot>();
        public ICollection<Reservation> Reservations { get; set; } = new List<Reservation>();
        public ICollection<ParkingZoneOccupancyLog> OccupancyLogs { get; set; } = new List<ParkingZoneOccupancyLog>();
        public ICollection<ReviewRating> Reviews { get; set; } = new List<ReviewRating>();
        public ICollection<ParkingPricingRule> PricingRules { get; set; } = new List<ParkingPricingRule>();
    }
}