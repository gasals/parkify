namespace parkify.Model.SearchObject
{
    public class NotificationSearch : BaseSearchObject
    {
        public int? UserId { get; set; }
        public bool? IsRead { get; set; }
    }
}
