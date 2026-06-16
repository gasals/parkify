using System.ComponentModel.DataAnnotations;

namespace parkify.Model.Requests
{
    public class ParkingSpotInsertRequest
    {
        [Range(1, int.MaxValue, ErrorMessage = "ParkingZoneId mora biti veći od 0.")]
        public int ParkingZoneId { get; set; }

        [Range(1, 2, ErrorMessage = "Tip mjesta mora biti 1 (Standard) ili 2 (Disabled).")]
        public int Type { get; set; }

        [Range(1, 50, ErrorMessage = "Red mora biti između 1 i 50.")]
        public int? RowNumber { get; set; }

        [Range(1, 50, ErrorMessage = "Kolona mora biti između 1 i 50.")]
        public int? ColumnNumber { get; set; }
        public bool IsAvailable { get; set; } = true;
    }
}