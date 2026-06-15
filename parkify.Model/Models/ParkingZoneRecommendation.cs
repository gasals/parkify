namespace parkify.Model.Models
{
    public class ParkingZoneRecommendation
    {
        public ParkingZone Zone { get; set; } = null!;
        public double Score { get; set; }
        public List<string> Reasons { get; set; } = new();
    }
}