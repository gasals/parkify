namespace parkify.Model.Models
{
    public class Payment
    {
        public int Id { get; set; }
        public string PaymentCode { get; set; } = string.Empty;
        public int ReservationId { get; set; }
        public int UserId { get; set; }
        public decimal Amount { get; set; }
        public string Currency { get; set; } = "BAM";
        public PaymentStatus Status { get; set; } = PaymentStatus.Pending;
        public string StripePaymentIntentId { get; set; }
        public string StripeSessionId { get; set; }
        public string PaymentMethod { get; set; } = "stripe";
        public string TransactionId { get; set; }
        public DateTime Created { get; set; } = DateTime.UtcNow;
        public DateTime? Modified { get; set; }
        public DateTime? Completed { get; set; }
        public DateTime? Refunded { get; set; }
        public string? RefundReason { get; set; }

    }

    public enum PaymentStatus
    {
        Pending = 1,
        Processing = 2,
        Completed = 3,
        Failed = 4,
        Refunded = 5
    }
}