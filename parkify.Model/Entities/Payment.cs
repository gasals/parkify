namespace parkify.Model.Entities
{
    public class Payment
    {
        public int Id { get; set; }
        public string PaymentCode { get; set; } = string.Empty;
        public int ReservationId { get; set; }
        public string UserId { get; set; } = string.Empty;
        public decimal Amount { get; set; }
        public string Currency { get; set; } = "BAM";
        public PaymentStatus Status { get; set; } = PaymentStatus.Pending;
        public string StripePaymentIntentId { get; set; } = string.Empty;
        public string StripeSessionId { get; set; } = string.Empty;
        public string PaymentMethod { get; set; } = "stripe";
        public string TransactionId { get; set; } = string.Empty;
        public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
        public DateTime? CompletedDate { get; set; }
        public DateTime? RefundedDate { get; set; }
        public string RefundReason { get; set; } = string.Empty;

        public required Reservation Reservation { get; set; }
        public required User User { get; set; }
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