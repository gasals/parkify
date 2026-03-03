using parkify.Model.Models;
using parkify.Model.SearchObject;

namespace parkify.Service.Interfaces
{
    public interface IWalletTransactionService : IService<WalletTransaction, WalletTransactionSearchObject>
    {
    }
}