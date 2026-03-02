using Microsoft.AspNetCore.Mvc;
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
    }
}