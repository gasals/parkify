using MapsterMapper;
using parkify.Model.SearchObject;
using parkify.Service.Database;
using parkify.Service.Interfaces;

namespace parkify.Service.Services
{
    public class WalletService : BaseService<Model.Models.Wallet, WalletSearchObject, Database.Wallet>, IWalletService
    {
        public WalletService(ParkifyContext context, IMapper mapper) : base(context, mapper)
        {
        }

        public override IQueryable<Database.Wallet> AddFilter(WalletSearchObject search, IQueryable<Database.Wallet> query)
        {
            query = base.AddFilter(search, query);

            if (search?.UserId.HasValue == true)
            {
                query = query.Where(x => x.UserId == search.UserId);
            }

            return query;
        }
    }
}