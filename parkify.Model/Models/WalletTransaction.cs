namespace parkify.Model.Models
{
    public class WalletTransaction
    {
        public int Id { get; set; }
        public int WalletId { get; set; }
        public decimal Amount { get; set; }
        public int Type { get; set; }
        public DateTime Created { get; set; }
    }
}