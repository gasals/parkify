namespace parkify.Model.SearchObject
{
    public class ParkingZoneSearch : BaseSearchObject
    {
        public string? Name { get; set; }
        public string? City { get; set; }
        public bool IncludeSpots { get; set; }
    }
}