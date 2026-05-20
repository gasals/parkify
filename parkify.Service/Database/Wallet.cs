namespace parkify.Service.Database
{
    public class Wallet
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public decimal Balance { get; set; }
        public DateTime Created { get; set; } = DateTime.UtcNow;
        public DateTime? Modified { get; set; }

        public User User { get; set; } = null!;
        public ICollection<Payment> Payments { get; set; } = new List<Payment>();
        public ICollection<WalletTransaction> Transactions { get; set; } = new List<WalletTransaction>();
    }
}