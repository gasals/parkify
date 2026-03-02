using System;
using System.ComponentModel.DataAnnotations.Schema;

namespace parkify.Service.Database
{
    public class WalletTransaction
    {
        public int Id { get; set; }
        public int WalletId { get; set; }
        public decimal Amount { get; set; }
        public WalletTransactionType Type { get; set; }
        public DateTime Created { get; set; } = DateTime.UtcNow;
        public DateTime? Modified { get; set; }
    }

    public enum WalletTransactionType
    {
        Reservation = 1,
        TopUp = 2,
        Cancellation = 3,
        Extra = 4
    }
}