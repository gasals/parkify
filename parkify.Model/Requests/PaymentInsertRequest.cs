using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace parkify.Model.Requests
{
    public class PaymentInsertRequest : IValidatableObject
    {
        [Range(1, int.MaxValue, ErrorMessage = "ReservationId mora biti veći od 0.")]
        public int? ReservationId { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "WalletId mora biti veći od 0.")]
        public int? WalletId { get; set; }

        [JsonIgnore]
        public int UserId { get; set; }

        [Range(typeof(decimal), "0.01", "10000.00", ErrorMessage = "Iznos mora biti između 0.01 i 10000.00.")]
        public decimal? Amount { get; set; }

        [StringLength(200, ErrorMessage = "StripePaymentIntentId ne smije imati više od 200 znakova.")]
        public string? StripePaymentIntentId { get; set; }

        public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
        {
            if (!ReservationId.HasValue && !WalletId.HasValue)
            {
                yield return new ValidationResult(
                    "Payment mora biti vezan ili za ReservationId ili za WalletId.",
                    new[] { nameof(ReservationId), nameof(WalletId) });
            }

            if (WalletId.HasValue && (!Amount.HasValue || Amount.Value <= 0))
            {
                yield return new ValidationResult(
                    "Za dopunu novčanika morate navesti iznos veći od 0.",
                    new[] { nameof(Amount) });
            }
        }
    }
}
