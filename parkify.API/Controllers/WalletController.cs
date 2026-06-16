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
        public override PagedResult<Wallet> GetList([FromQuery] WalletSearchObject searchObject)
        {
            if (!IsCurrentUserAdmin())
            {
                searchObject.UserId = GetCurrentUserIdOrThrow();
            }

            return base.GetList(searchObject);
        }

        [HttpGet("{id}")]
        public override Wallet GetById(int id)
        {
            var wallet = base.GetById(id);

            if (!IsCurrentUserAdmin() && wallet.UserId != GetCurrentUserIdOrThrow())
                throw new UnauthorizedAccessException("Nemate pravo pristupa ovom novčaniku.");

            return wallet;
        }
    }
}