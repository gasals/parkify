namespace parkify.Model.Models
{
    public class AuthResponse
    {
        public string Token { get; set; } = string.Empty;
        public int Id { get; set; }
        public bool IsAdmin { get; set; }
        public bool IsActive { get; set; }
    }
}