using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using parkify.Model.Constants;
using parkify.Model.Helpers;
using parkify.Model.SearchObject;
using parkify.Service.Interfaces;
using System.Security.Claims;

namespace parkify.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class BaseController<TModel, TSearch> : ControllerBase where TSearch : BaseSearchObject
    {
        protected IService<TModel, TSearch> _service;
        public BaseController(IService<TModel, TSearch> service)
        {
            _service = service;
        }
        [HttpGet]
        public virtual async Task<PagedResult<TModel>> GetList([FromQuery] TSearch searchObject)
        {
            return await _service.GetPaged(searchObject);
        }

        [HttpGet("{id}")]
        public virtual async Task<TModel?> GetById(int id)
        {
            return await _service.GetById(id);
        }

        protected int GetCurrentUserIdOrThrow()
        {
            var claimValue = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!int.TryParse(claimValue, out var currentUserId))
            {
                throw new UnauthorizedAccessException("Korisnički identitet nije validan.");
            }

            return currentUserId;
        }

        protected bool IsCurrentUserAdmin()
        {
            return User.IsInRole(AppRoles.Admin);
        }
    }
}
