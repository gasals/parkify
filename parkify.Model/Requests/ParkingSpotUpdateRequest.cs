namespace parkify.Model.Requests
{
    public class ParkingSpotUpdateRequest
    {
        public string SpotCode { get; set; } = null!;
        public int? ParkingZoneId { get; set; }
        public int? Type { get; set; }
        public int? RowNumber { get; set; }
        public int? ColumnNumber { get; set; }
        public bool IsAvailable { get; set; }
    }
}