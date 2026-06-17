namespace parkify.Model.SearchObject
{
    public class BaseSearchObject
    {
        public const int DefaultPage = 1;
        public const int DefaultPageSize = 20;
        public const int MaxPageSize = 100;

        public int Page { get; set; } = DefaultPage;

        public int PageSize { get; set; } = DefaultPageSize;

        public void NormalizePaging()
        {
            if (Page < 1)
                Page = DefaultPage;

            if (PageSize < 1)
                PageSize = DefaultPageSize;

            if (PageSize > MaxPageSize)
                PageSize = MaxPageSize;
        }

    }
}
