using parkify.Model.Models;

namespace parkify.Model.Requests
{
    public class ReservationUpdateRequest
    {
        public ReservationStatus? Status { get; set; }
        public bool? IsCheckedIn { get; set; }
        public bool? IsCheckedOut { get; set; }
        public DateTime? CheckInTime { get; set; }
        public DateTime? CheckOutTime { get; set; }
    }
}
