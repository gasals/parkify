namespace parkify.Model.Requests
{
    public class PaymentInsertRequest
    {
        public int? ReservationId { get; set; }
        public int? WalletId { get; set; }
        public int UserId { get; set; }
        public decimal Amount { get; set; }
    }
}
