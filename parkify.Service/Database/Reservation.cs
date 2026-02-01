namespace parkify.Service.Database
{
    public class Reservation
    {
        public int Id { get; set; }
        public string ReservationCode { get; set; } = string.Empty;
        public int UserId { get; set; }
        public int ParkingZoneId { get; set; }
        public int ParkingSpotId { get; set; }
        public DateTime ReservationStart { get; set; }
        public DateTime ReservationEnd { get; set; }
        public int DurationInHours { get; set; }
        public ReservationStatus Status { get; set; } = ReservationStatus.Pending;
        public bool IsCheckedIn { get; set; } = false;
        public bool IsCheckedOut { get; set; } = false;
        public decimal CalculatedPrice { get; set; }
        public decimal? DiscountAmount { get; set; }
        public decimal FinalPrice { get; set; }
        public bool RequiresDisabledSpot { get; set; } = false;
        public string Notes { get; set; } = string.Empty;
        public string QRCodeData { get; set; } = string.Empty;
        public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
        public DateTime? CheckInTime { get; set; }
        public DateTime? CheckOutTime { get; set; }
        public DateTime? UpdatedDate { get; set; }

        public required User User { get; set; }
        public required ParkingZone ParkingZone { get; set; }
        public required ParkingSpot ParkingSpot { get; set; }
        public required Payment Payment { get; set; }
    }

    public enum ReservationStatus
    {
        Pending = 1,
        Confirmed = 2,
        Active = 3,
        Completed = 4,
        Cancelled = 5,
        NoShow = 6
    }
}