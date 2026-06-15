using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using parkify.Model.Exceptions;
using System.Net;

namespace parkify.API.Filters
{
    public class ExceptionFilter : ExceptionFilterAttribute
    {
        private ILogger<ExceptionFilter> _logger;
        public ExceptionFilter(ILogger<ExceptionFilter> logger)
        {
            _logger = logger;
        }
        public override void OnException(ExceptionContext context)
        {
            if (context.Exception is NotFoundException)
            {
                _logger.LogWarning(context.Exception, context.Exception.Message);
                context.ModelState.AddModelError("notFound", context.Exception.Message);
                context.HttpContext.Response.StatusCode = (int)HttpStatusCode.NotFound;
            }
            else if (context.Exception is BusinessException || context.Exception is UserException)
            {
                _logger.LogWarning(context.Exception, context.Exception.Message);
                context.ModelState.AddModelError("userError", context.Exception.Message);
                context.HttpContext.Response.StatusCode = (int)HttpStatusCode.BadRequest;
            }
            else if (context.Exception is UnauthorizedAccessException)
            {
                _logger.LogWarning(context.Exception, context.Exception.Message);
                context.ModelState.AddModelError("forbidden", context.Exception.Message);
                context.HttpContext.Response.StatusCode = (int)HttpStatusCode.Forbidden;
            }
            else
            {
                _logger.LogError(context.Exception, context.Exception.Message);
                context.ModelState.AddModelError("ERROR", "Server side error, please check logs.");
                context.HttpContext.Response.StatusCode = (int)HttpStatusCode.InternalServerError;
            }

            var list = context.ModelState.Where(x => x.Value.Errors.Count() > 0).ToDictionary(x => x.Key, y => y.Value.Errors.Select(z => z.ErrorMessage));

            context.Result = new JsonResult(new { errors = list });
        }
    }
}