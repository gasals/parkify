using parkify.Model.SearchObject;

namespace parkify.Model.SearchObject
{
    public class PreferenceSearch : BaseSearchObject
    {
        public int? UserId { get; set; }
        public string PreferredCity { get; set; }
    }
}
