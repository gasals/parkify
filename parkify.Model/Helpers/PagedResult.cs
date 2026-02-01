namespace parkify.Model.Helpers
{
    public class PagedResult<T>
    {
        public int? Count { get; set; }
        public IList<T> Results { get; set; }
    }
}
