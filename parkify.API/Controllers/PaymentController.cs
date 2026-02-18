using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Stripe;
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
        private readonly IConfiguration _configuration;

        public PaymentsController(IPaymentService service, IConfiguration configuration) : base(service)
        {
            _paymentService = service;
            _configuration = configuration;
            StripeConfiguration.ApiKey = configuration["Stripe:SecretKey"];
        }

        [HttpPost("create-with-intent")]
        [Authorize]
        public async Task<IActionResult> CreatePaymentWithIntent([FromBody] PaymentInsertRequest request)
        {
            try
            {
                var options = new PaymentIntentCreateOptions
                {
                    Amount = (long)(request.Amount * 100),
                    Currency = "bam",
                    PaymentMethodTypes = new List<string> { "card" },
                    Metadata = new Dictionary<string, string>
                    {
                        { "reservationId", request.ReservationId.ToString() },
                        { "userId", request.UserId.ToString() }
                    }
                };

                var service = new PaymentIntentService();
                var paymentIntent = await service.CreateAsync(options);

                var payment = _paymentService.Insert(request);
                
                return Ok(new
                {
                    payment.Id,
                    payment.PaymentCode,
                    paymentIntent.ClientSecret,
                    StripePaymentIntentId = paymentIntent.Id,
                    payment.Amount,
                    payment.Status
                });
            }
            catch (Exception ex)
            {
                return BadRequest(new { error = ex.Message });
            }
        }

        [HttpPut("{id}/confirm")]
        [Authorize]
        public async Task<IActionResult> ConfirmPayment(int id)
        {
            try
            {
                await _paymentService.ConfirmPayment(id);
                return Ok(new { message = "Plaćanje potvrđeno" });
            }
            catch (Exception ex)
            {
                return BadRequest(new { error = ex.Message });
            }
        }

        [HttpPut("{id}/refund")]
        [Authorize]
        public async Task<IActionResult> RefundPayment(int id, [FromBody] RefundRequest request)
        {
            try
            {
                await _paymentService.RefundPayment(id, request.Reason);
                return Ok(new { message = "Plaćanje vraćeno" });
            }
            catch (Exception ex)
            {
                return BadRequest(new { error = ex.Message });
            }
        }
    }

}