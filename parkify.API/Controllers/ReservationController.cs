using parkify.Model.Models;
using parkify.Model.Requests;
using parkify.Model.SearchObject;
using parkify.Service.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using parkify.Model.Constants;

namespace parkify.API.Controllers
{
    public class ReservationController : BaseCRUDController<Reservation, ReservationSearch, ReservationInsertRequest, ReservationUpdateRequest>
    {
        public ReservationController(IReservationService service) : base(service)
        {
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
