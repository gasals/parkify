using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using parkify.Model.Constants;
using parkify.Model.Helpers;
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

        [HttpGet]
        [Authorize]
        public override async Task<PagedResult<Payment>> GetList([FromQuery] PaymentSearch searchObject)
        {
            if (!IsCurrentUserAdmin())
            {
                searchObject.UserId = GetCurrentUserIdOrThrow();
            }

            return await base.GetList(searchObject);
        }

        [HttpGet("{id}")]
        [Authorize]
        public override async Task<Payment?> GetById(int id)
        {
            var payment = await base.GetById(id);

            if (payment == null)
                return null;

            if (!IsCurrentUserAdmin() && payment.UserId != GetCurrentUserIdOrThrow())
                throw new UnauthorizedAccessException("Nemate pravo pristupa ovom plaćanju.");

            return payment;
        }

        [HttpPost]
        [Authorize]
        public override async Task<Payment> Insert([FromBody] PaymentInsertRequest request)
        {
            var currentUserId = GetCurrentUserIdOrThrow();
            request.UserId = currentUserId;

            return await base.Insert(request);
        }

        [HttpPut("{id}")]
        [Authorize(Roles = AppRoles.Admin)]
        public override async Task<Payment> Update(int id, [FromBody] PaymentUpdateRequest request)
        {
            return await base.Update(id, request);
        }

        [HttpPost("create-with-intent")]
        [Authorize]
        public async Task<IActionResult> CreatePaymentWithIntent([FromBody] PaymentInsertRequest request)
        {
            var currentUserId = GetCurrentUserIdOrThrow();
            request.UserId = currentUserId;

            var result = await _paymentService.CreatePaymentWithIntent(request);
            return Ok(result);
        }

        [HttpPut("{id}/confirm")]
        [Authorize]
        public async Task<IActionResult> ConfirmPayment(int id)
        {
            if (!IsCurrentUserAdmin())
            {
                var existingPayment = await base.GetById(id);
                if (existingPayment == null)
                    return NotFound();

                if (existingPayment.UserId != GetCurrentUserIdOrThrow())
                    throw new UnauthorizedAccessException("Nemate pravo potvrde ovog plaćanja.");
            }

            var confirmedPayment = await _paymentService.ConfirmPayment(id);
            return Ok(confirmedPayment);
        }

        [HttpPut("{id}/refund")]
        [Authorize]
        public async Task<IActionResult> RefundPayment(int id, [FromBody] RefundRequest request)
        {
            if (string.IsNullOrWhiteSpace(request?.Reason))
            {
                return BadRequest(new { error = "Razlog refundacije je obavezan." });
            }

            if (!IsCurrentUserAdmin())
            {
                var existingPayment = await base.GetById(id);
                if (existingPayment == null)
                    return NotFound();

                if (existingPayment.UserId != GetCurrentUserIdOrThrow())
                    throw new UnauthorizedAccessException("Nemate pravo refundacije ovog plaćanja.");
            }

            var refundedPayment = await _paymentService.RefundPayment(id, request.Reason);
            return Ok(refundedPayment);
        }
    }

}