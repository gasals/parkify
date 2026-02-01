namespace parkify.Model.SearchObject
{
    public class UserSearch : BaseSearchObject
    {
        public string? Username { get; set; }
        public string? Email { get; set; }
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
    }
}