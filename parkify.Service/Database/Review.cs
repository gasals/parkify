namespace parkify.Service.Database
{
    public class Review
    {
        public int Id { get; set; }
        public int ParkingZoneId { get; set; }
        public int UserId { get; set; }
        public int Rating { get; set; }
        public string ReviewText { get; set; } = string.Empty;
        public DateTime Created { get; set; } = DateTime.UtcNow;
        public DateTime? Modified { get; set; }

    }
}