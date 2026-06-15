using parkify.Model.Models;

namespace parkify.Service.Interfaces
{
    public interface IAuthTokenService
    {
        AuthResponse CreateAuthResponse(User user);
    }
}