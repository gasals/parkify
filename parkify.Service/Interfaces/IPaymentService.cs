using parkify.Model.Models;
using parkify.Model.Requests;
using parkify.Model.SearchObject;

namespace parkify.Service.Interfaces
{
    public interface IPaymentService : ICRUDService<Payment, PaymentSearch, PaymentInsertRequest, PaymentUpdateRequest>
    {
        Task<Payment> ConfirmPayment(int paymentId);
        Task<Payment> RefundPayment(int paymentId, string reason);
    }
}