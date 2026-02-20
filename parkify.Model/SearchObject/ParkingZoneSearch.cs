namespace parkify.Model.SearchObject
{
    public class ParkingZoneSearch : BaseSearchObject
    {
        public string? Name { get; set; }
        public int? CityId { get; set; }
        public bool IncludeSpots { get; set; }
    }
}