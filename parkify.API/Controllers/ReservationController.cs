using parkify.Model.Models;
using parkify.Model.Requests;
using parkify.Model.SearchObject;
using parkify.Service.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using parkify.Model.Constants;
using parkify.Model.Helpers;

namespace parkify.API.Controllers
{
    public class ReservationController : BaseCRUDController<Reservation, ReservationSearch, ReservationInsertRequest, ReservationUpdateRequest>
    {
        public ReservationController(IReservationService service) : base(service)
        {
        }

        [HttpGet]
        [Authorize]
        public override PagedResult<Reservation> GetList([FromQuery] ReservationSearch searchObject)
        {
            if (!IsCurrentUserAdmin())
            {
                searchObject.UserId = GetCurrentUserIdOrThrow();
            }

            return base.GetList(searchObject);
        }

        [HttpGet("{id}")]
        [Authorize]
        public override Reservation GetById(int id)
        {
            var reservation = base.GetById(id);

            if (!IsCurrentUserAdmin() && reservation.UserId != GetCurrentUserIdOrThrow())
                throw new UnauthorizedAccessException("Nemate pravo pristupa ovoj rezervaciji.");

            return reservation;
        }

        [HttpPost]
        [Authorize]
        public override Reservation Insert([FromBody] ReservationInsertRequest request)
        {
            var currentUserId = GetCurrentUserIdOrThrow();
            if (!IsCurrentUserAdmin())
            {
                request.UserId = currentUserId;
            }
            else if (request.UserId <= 0)
            {
                request.UserId = currentUserId;
            }

            return base.Insert(request);
        }

        [HttpPut("{id}")]
        [Authorize]
        public override Reservation Update(int id, [FromBody] ReservationUpdateRequest request)
        {
            if (!IsCurrentUserAdmin())
            {
                var reservation = base.GetById(id);
                if (reservation.UserId != GetCurrentUserIdOrThrow())
                    throw new UnauthorizedAccessException("Nemate pravo izmjene ove rezervacije.");
            }

            return base.Update(id, request);
        }

        [HttpGet("report/pdf")]
        [Authorize(Roles = AppRoles.Admin)]
        public IActionResult GetAdminReportPdf([FromQuery] DateTime? from, [FromQuery] DateTime? to)
        {
            var pdfBytes = (_service as IReservationService)!.GenerateAdminReportPdf(from, to);
            var fileName = $"parkify-report-{DateTime.UtcNow:yyyyMMddHHmmss}.pdf";
            return File(pdfBytes, "application/pdf", fileName);
        }

        [HttpGet("report/finance/pdf")]
        [Authorize(Roles = AppRoles.Admin)]
        public IActionResult GetFinanceReportPdf([FromQuery] DateTime? from, [FromQuery] DateTime? to, [FromQuery] int? userId)
        {
            var pdfBytes = (_service as IReservationService)!.GenerateFinanceReportPdf(from, to, userId);
            var fileName = $"parkify-finance-report-{DateTime.UtcNow:yyyyMMddHHmmss}.pdf";
            return File(pdfBytes, "application/pdf", fileName);
        }
    }
}
