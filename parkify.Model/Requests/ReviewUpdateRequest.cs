using System.ComponentModel.DataAnnotations;

namespace parkify.Model.Requests
{
    public class ReviewUpdateRequest
    {
        [Range(1, 5, ErrorMessage = "Ocjena mora biti između 1 i 5.")]
        public int? Rating { get; set; }

        [StringLength(500, MinimumLength = 10, ErrorMessage = "Recenzija mora imati 10-500 znakova.")]
        public string? ReviewText { get; set; }
    }
}
