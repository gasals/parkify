namespace parkify.Model.Models
{
    public class Wallet
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public decimal Balance { get; set; }
        public DateTime Created { get; set; }
        public DateTime? Modified { get; set; }
    }
}