namespace parkify.RabbitMQ.Models
{
    public class NotificationMessage
    {
        public int UserId { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Message { get; set; } = string.Empty;
        public int Type { get; set; }
        public NotificationChannel Channel { get; set; }
        public int? ReservationId { get; set; }
        public int? ParkingZoneId { get; set; }
    }

    public enum NotificationChannel
    {
        InApp = 1,
        Email = 2,
        Both = 3
    }
}
