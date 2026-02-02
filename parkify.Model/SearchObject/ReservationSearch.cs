using parkify.Model.SearchObject;

namespace parkify.Model.SearchObject
{
    public class ReservationSearch : BaseSearchObject
    {
        public int? UserId { get; set; }
        public int? ParkingZoneId { get; set; }
        public int? Status { get; set; }
    }
}
