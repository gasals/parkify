using Microsoft.AspNetCore.Mvc;
using parkify.Model.Helpers;
using parkify.Model.Models;
using parkify.Model.SearchObject;
using parkify.Service.Interfaces;

namespace parkify.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class WalletController : BaseController<Wallet, WalletSearchObject>
    {
        public WalletController(IWalletService service) : base(service)
        {
        }

        [HttpGet]
        public override async Task<PagedResult<Wallet>> GetList([FromQuery] WalletSearchObject searchObject)
        {
            if (!IsCurrentUserAdmin())
            {
                searchObject.UserId = GetCurrentUserIdOrThrow();
            }

            return await base.GetList(searchObject);
        }

        [HttpGet("{id}")]
        public override async Task<Wallet?> GetById(int id)
        {
            var wallet = await base.GetById(id);

            if (wallet == null)
                return null;

            if (!IsCurrentUserAdmin() && wallet.UserId != GetCurrentUserIdOrThrow())
                throw new UnauthorizedAccessException("Nemate pravo pristupa ovom novčaniku.");

            return wallet;
        }
    }
}