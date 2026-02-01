namespace parkify.Model.Requests
{
    public class NotificationUpdateRequest
    {
        public string Title { get; set; }
        public string Message { get; set; }
        public int Type { get; set; }
        public bool IsRead { get; set; }
        public DateTime? ReadDate { get; set; }
    }
}
