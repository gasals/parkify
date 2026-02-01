namespace parkify.Service.Database
{
    public class Notification
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Message { get; set; } = string.Empty;
        public NotificationType Type { get; set; }
        public int? ReservationId { get; set; }
        public int? ParkingZoneId { get; set; }
        public bool IsRead { get; set; } = false;
        public DateTime Created { get; set; } = DateTime.UtcNow;
        public DateTime? Modified { get; set; }
        public DateTime? ReadDate { get; set; }

        public required User User { get; set; }
    }

    public enum NotificationType
    {
        ReservationConfirmed = 1,
        ReservationReminder = 2,
        PaymentSuccessful = 3,
        PaymentFailed = 4,
        AvailabilityAlert = 5,
        SpecialOffer = 6,
        ReservationCancelled = 7,
        CheckInReminder = 8,
        ParkingFull = 9
    }
}