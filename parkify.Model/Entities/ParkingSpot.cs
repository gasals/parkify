namespace parkify.Model.Entities
{
    public class ParkingSpot
    {
        public int Id { get; set; }
        public string SpotCode { get; set; } = string.Empty;
        public int ParkingZoneId { get; set; }
        public ParkingSpotType Type { get; set; } = ParkingSpotType.Standard;
        public int? RowNumber { get; set; }
        public int? ColumnNumber { get; set; }
        public bool IsAvailable { get; set; } = true;
        public DateTime CreatedDate { get; set; } = DateTime.UtcNow;

        public required ParkingZone ParkingZone { get; set; }
        public ICollection<Reservation> Reservations { get; set; } = new List<Reservation>();
    }

    public enum ParkingSpotType
    {
        Standard = 1,
        Disabled = 2,
        Covered = 3
    }
}