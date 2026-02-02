namespace parkify.Model.Models
{
    public class User
    {
        public int Id { get; set; }
        public string Username { get; set; } = null!;
        public string Email { get; set; } = null!;
        public string FirstName { get; set; } = null!;
        public string LastName { get; set; } = null!;
        public DateTime Created { get; set; } = DateTime.UtcNow;
        public DateTime? Modified { get; set; }
        public bool IsActive { get; set; } = true;
        public string? Address { get; set; }
        public string? City { get; set; }
        public string PasswordHash { get; set; }
        public string PasswordSalt { get; set; }
    }
}