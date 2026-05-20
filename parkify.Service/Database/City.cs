namespace parkify.Service.Database
{
    public class City
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public double Latitude { get; set; }
        public double Longitude { get; set; }

        public ICollection<ParkingZone> ParkingZones { get; set; } = new List<ParkingZone>();
        public ICollection<Preference> Preferences { get; set; } = new List<Preference>();
    }
}