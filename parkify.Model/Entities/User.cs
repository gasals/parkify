using Microsoft.AspNet.Identity.EntityFramework;


namespace parkify.Model.Entities
{
    public class User : IdentityUser
    {
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public DateTime RegistrationDate { get; set; } = DateTime.UtcNow;
        public bool IsActive { get; set; } = true;
        public string Address { get; set; } = string.Empty;
        public string City { get; set; } = string.Empty;

        // Relacije (kasnije će biti popunjene)
        public ICollection<Reservation> Reservations { get; set; } = new List<Reservation>();
        public ICollection<Payment> Payments { get; set; } = new List<Payment>();
        public ICollection<Notification> Notifications { get; set; } = new List<Notification>();
        public ICollection<Review> ReviewRatings { get; set; } = new List<Review>();
        public UserPreference UserPreference { get; set; }
    }
}