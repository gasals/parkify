namespace parkify.Model.Requests
{
    public class UserInsertRequest
    {
        public string Username { get; set; }
        public string Email { get; set; }
        public string Password { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string? Address { get; set; }
        public string? City { get; set; }
        public string PasswordConfirm { get; set; }
        public bool? IsAdmin { get; set; }
    }
}