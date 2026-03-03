namespace parkify.Service.Database
{
    public class Wallet
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public decimal Balance { get; set; }
        public DateTime Created { get; set; } = DateTime.UtcNow;
        public DateTime? Modified { get; set; }
    }
}