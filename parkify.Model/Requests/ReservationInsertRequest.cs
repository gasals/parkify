namespace parkify.Model.Requests
{
    public class ReservationInsertRequest
    {
        public int UserId { get; set; }
        public int ParkingZoneId { get; set; }
        public int ParkingSpotId { get; set; }
        public DateTime ReservationStart { get; set; }
        public DateTime ReservationEnd { get; set; }
        public int DurationInHours { get; set; }
        public decimal CalculatedPrice { get; set; }
        public decimal? DiscountAmount { get; set; }
        public decimal FinalPrice { get; set; }
        public bool RequiresDisabledSpot { get; set; } = false;
        public string Notes { get; set; }
    }
}
