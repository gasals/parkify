namespace parkify.Model.Requests
{
    public class PaymentUpdateRequest
    {
        public int Status { get; set; }
        public string? StripePaymentIntentId { get; set; }
        public string? TransactionId { get; set; }
        public string? RefundReason { get; set; }
    }
}
