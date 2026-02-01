namespace parkify.Model.Requests
{
    public class NotificationInsertRequest
    {
        public int UserId { get; set; }
        public string Title { get; set; }
        public string Message { get; set; }
        public int Type { get; set; }
        public int? ReservationId { get; set; }
        public int? ParkingZoneId { get; set; }
    }
}
