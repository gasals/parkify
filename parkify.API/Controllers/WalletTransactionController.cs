using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
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
        public override async Task<PagedResult<WalletTransaction>> GetList([FromQuery] WalletTransactionSearchObject searchObject)
        {
            if (!IsCurrentUserAdmin())
            {
                var currentUserId = GetCurrentUserIdOrThrow();
                var walletId = await _context.Wallets
                    .Where(w => w.UserId == currentUserId)
                    .Select(w => (int?)w.Id)
                    .FirstOrDefaultAsync();

                if (!walletId.HasValue)
                    return new PagedResult<WalletTransaction>();

                searchObject.WalletId = walletId.Value;
            }

            return await base.GetList(searchObject);
        }

        [HttpGet("{id}")]
        public override async Task<WalletTransaction?> GetById(int id)
        {
            var item = await base.GetById(id);
            if (item == null)
                return null;

            if (!IsCurrentUserAdmin())
            {
                var currentUserId = GetCurrentUserIdOrThrow();
                var isOwner = await _context.Wallets.AnyAsync(w => w.Id == item.WalletId && w.UserId == currentUserId);
                if (!isOwner)
                    throw new UnauthorizedAccessException("Nemate pravo pristupa ovoj transakciji.");
            }

            return item;
        }

    }
}