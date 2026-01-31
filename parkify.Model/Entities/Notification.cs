namespace parkify.Model.Entities
{
    public class Notification
    {
        public int Id { get; set; }
        public string UserId { get; set; } = string.Empty;
        public string Title { get; set; } = string.Empty;
        public string Message { get; set; } = string.Empty;
        public NotificationType Type { get; set; }
        public int? ReservationId { get; set; }
        public int? ParkingZoneId { get; set; }
        public bool IsRead { get; set; } = false;
        public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
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