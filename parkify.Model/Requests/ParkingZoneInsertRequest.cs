namespace parkify.Model.Requests
{
    public class ParkingZoneInsertRequest
    {
        public string Name { get; set; }
        public string Description { get; set; }
        public string Address { get; set; }
        public string City { get; set; }
        public double Latitude { get; set; }
        public double Longitude { get; set; }
        public decimal PricePerHour { get; set; }
        public decimal? DailyRate { get; set; }
        public bool IsActive { get; set; } = false;
    }
}