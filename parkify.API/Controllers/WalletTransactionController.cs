using Microsoft.AspNetCore.Mvc;
using parkify.Model.Helpers;
using parkify.Model.Models;
using parkify.Model.SearchObject;
using parkify.Service.Interfaces;
using ParkifyContext = parkify.Service.Database.ParkifyContext;

namespace parkify.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class WalletTransactionController : BaseController<WalletTransaction, WalletTransactionSearchObject>
    {
        private readonly ParkifyContext _context;

        public WalletTransactionController(IWalletTransactionService service, ParkifyContext context) : base(service)
        {
            _context = context;
        }

        [HttpGet]
        public override PagedResult<WalletTransaction> GetList([FromQuery] WalletTransactionSearchObject searchObject)
        {
            if (!IsCurrentUserAdmin())
            {
                var currentUserId = GetCurrentUserIdOrThrow();
                var walletId = _context.Wallets
                    .Where(w => w.UserId == currentUserId)
                    .Select(w => (int?)w.Id)
                    .FirstOrDefault();

                if (!walletId.HasValue)
                    return new PagedResult<WalletTransaction>();

                searchObject.WalletId = walletId.Value;
            }

            return base.GetList(searchObject);
        }

        [HttpGet("{id}")]
        public override WalletTransaction GetById(int id)
        {
            var item = base.GetById(id);

            if (!IsCurrentUserAdmin())
            {
                var currentUserId = GetCurrentUserIdOrThrow();
                var isOwner = _context.Wallets.Any(w => w.Id == item.WalletId && w.UserId == currentUserId);
                if (!isOwner)
                    throw new UnauthorizedAccessException("Nemate pravo pristupa ovoj transakciji.");
            }

            return item;
        }

    }
}