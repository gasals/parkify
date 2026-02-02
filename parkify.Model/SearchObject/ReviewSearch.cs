using parkify.Model.SearchObject;

namespace parkify.Model.SearchObject
{
    public class ReviewSearch : BaseSearchObject
    {
        public int? ParkingZoneId { get; set; }
        public int? UserId { get; set; }
        public int? RatingMin { get; set; }
    }
}
