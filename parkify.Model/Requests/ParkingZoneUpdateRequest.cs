namespace parkify.Model.Requests
{
    public class ParkingZoneUpdateRequest
    {
        public string? Name { get; set; }
        public string? Description { get; set; }
        public string? Address { get; set; }
        public string? City { get; set; }
        public double? Latitude { get; set; }
        public double? Longitude { get; set; }
        public int? TotalSpots { get; set; }
        public int? DisabledSpots { get; set; }
        public int? CoveredSpots { get; set; }
        public int? AvailableSpots { get; set; }
        public decimal? PricePerHour { get; set; }
        public decimal? DailyRate { get; set; }
        public bool? IsActive { get; set; }
    }
}