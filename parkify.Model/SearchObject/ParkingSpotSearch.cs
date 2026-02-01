using parkify.Model.SearchObject;

namespace parkify.Model.SearchObject
{
    public class ParkingSpotSearch : BaseSearchObject
    {
        public int? ParkingZoneId { get; set; }
        public string? SpotCode { get; set; }
        public bool? IsAvailable { get; set; }
        public int? Type { get; set; }
    }
}