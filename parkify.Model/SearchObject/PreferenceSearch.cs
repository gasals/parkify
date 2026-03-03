namespace parkify.Model.SearchObject
{
    public class PreferenceSearch : BaseSearchObject
    {
        public int? UserId { get; set; }
        public int? PreferredCityId { get; set; }
    }
}
