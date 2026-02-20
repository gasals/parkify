namespace parkify.Model.Requests
{
    public class CityUpdateRequest
    {
        public string? Name { get; set; }
        public double? Latitude { get; set; }
        public double? Longitude { get; set; }
        public string? Country { get; set; }
    }
}