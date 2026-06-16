using System.ComponentModel.DataAnnotations;

namespace parkify.Model.Requests
{
    public class PaymentUpdateRequest
    {
        [Range(1, 5, ErrorMessage = "Status plaćanja mora biti između 1 i 5.")]
        public int Status { get; set; }

        [StringLength(200, ErrorMessage = "StripePaymentIntentId ne smije imati više od 200 znakova.")]
        public string? StripePaymentIntentId { get; set; }

        [StringLength(200, ErrorMessage = "TransactionId ne smije imati više od 200 znakova.")]
        public string? TransactionId { get; set; }

        [StringLength(500, ErrorMessage = "RefundReason ne smije imati više od 500 znakova.")]
        public string? RefundReason { get; set; }
    }
}
