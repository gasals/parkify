using MapsterMapper;
using parkify.Model.Models;
using parkify.Model.SearchObject;
using parkify.Service.Interfaces;

namespace parkify.Service.Services
{
    public class WalletTransactionService : BaseService<WalletTransaction, WalletTransactionSearchObject, Database.WalletTransaction>, IWalletTransactionService
    {
        public WalletTransactionService(Database.ParkifyContext context, IMapper mapper) : base(context, mapper)
        {
        }

        public override IQueryable<Database.WalletTransaction> AddFilter(WalletTransactionSearchObject search, IQueryable<Database.WalletTransaction> query)
        {
            query = base.AddFilter(search, query);

            if (search?.WalletId.HasValue == true)
            {
                query = query.Where(x => x.WalletId == search.WalletId);
            }

            return query;
        }
    }
}