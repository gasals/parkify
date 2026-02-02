using parkify.Model.SearchObject;

namespace parkify.Model.SearchObject
{
    public class PaymentSearch : BaseSearchObject
    {
        public int? UserId { get; set; }
        public int? ReservationId { get; set; }
        public int? Status { get; set; }
    }
}
