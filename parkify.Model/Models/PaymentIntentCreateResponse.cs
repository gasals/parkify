namespace parkify.Model.Models
{
    public class PaymentIntentCreateResponse
    {
        public int Id { get; set; }
        public string PaymentCode { get; set; } = string.Empty;
        public string ClientSecret { get; set; } = string.Empty;
        public string StripePaymentIntentId { get; set; } = string.Empty;
        public decimal Amount { get; set; }
        public int Status { get; set; }
    }
}
