namespace parkify.Service.Interfaces
{
    public interface ITokenRevocationService
    {
        void RevokeToken(string token, DateTime expiresAtUtc);
        void RevokeCurrentToken();
        bool IsTokenRevoked(string token);
    }
}
