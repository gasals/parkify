namespace parkify.Model.Requests
{
    public class ReviewInsertRequest
    {
        public int ParkingZoneId { get; set; }
        public int UserId { get; set; }
        public int Rating { get; set; }
        public string? ReviewText { get; set; }
    }
}
