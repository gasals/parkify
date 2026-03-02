using Microsoft.AspNetCore.Mvc;
using parkify.Model.Models;
using parkify.Model.SearchObject;
using parkify.Service.Interfaces;

namespace parkify.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class WalletTransactionController : BaseController<WalletTransaction, WalletTransactionSearchObject>
    {
        public WalletTransactionController(IWalletTransactionService service) : base(service)
        {
        }

    }
}