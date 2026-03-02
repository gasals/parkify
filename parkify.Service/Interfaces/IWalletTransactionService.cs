using parkify.Model.SearchObject;
using parkify.Model.Models;

namespace parkify.Service.Interfaces
{
    public interface IWalletTransactionService : IService<WalletTransaction, WalletTransactionSearchObject>
    {
    }
}