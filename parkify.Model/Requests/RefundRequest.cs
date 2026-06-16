using System.ComponentModel.DataAnnotations;

namespace parkify.Model.Requests
{
    public class RefundRequest
    {
        [Required(ErrorMessage = "Razlog refundacije je obavezan.")]
        [StringLength(500, MinimumLength = 5, ErrorMessage = "Razlog refundacije mora imati 5-500 znakova.")]
        public string Reason { get; set; }
    }
}
