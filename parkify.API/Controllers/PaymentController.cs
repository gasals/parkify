using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using parkify.Model.Models;
using parkify.Model.Requests;
using parkify.Model.SearchObject;
using parkify.Service.Interfaces;

namespace parkify.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class PaymentsController : BaseCRUDController<Payment, PaymentSearch, PaymentInsertRequest, PaymentUpdateRequest>
    {
        private readonly IPaymentService _paymentService;

        public PaymentsController(IPaymentService service) : base(service)
        {
            _paymentService = service;
        }

        [HttpPost("create-with-intent")]
        [Authorize]
        public async Task<IActionResult> CreatePaymentWithIntent([FromBody] PaymentInsertRequest request)
        {
            var result = await _paymentService.CreatePaymentWithIntent(request);
            return Ok(result);
        }

        [HttpPut("{id}/confirm")]
        [Authorize]
        public async Task<IActionResult> ConfirmPayment(int id)
        {
            var payment = await _paymentService.ConfirmPayment(id);
            return Ok(payment);
        }

        [HttpPut("{id}/refund")]
        [Authorize]
        public async Task<IActionResult> RefundPayment(int id, [FromBody] RefundRequest request)
        {
            if (string.IsNullOrWhiteSpace(request?.Reason))
            {
                return BadRequest(new { error = "Razlog refundacije je obavezan." });
            }

            var payment = await _paymentService.RefundPayment(id, request.Reason);
            return Ok(payment);
        }
    }

}