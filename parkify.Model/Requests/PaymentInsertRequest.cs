namespace parkify.Model.Requests
{
    public class PaymentInsertRequest
    {
        public int ReservationId { get; set; }
        public int UserId { get; set; }
        public decimal Amount { get; set; }
        public string Currency { get; set; } = "BAM";
        public string PaymentMethod { get; set; } = "stripe";
    }
}
