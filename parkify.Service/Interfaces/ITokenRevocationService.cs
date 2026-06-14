namespace parkify.Service.Interfaces
{
    public interface ITokenRevocationService
    {
        void RevokeToken(string token, DateTime expiresAtUtc);
        bool IsTokenRevoked(string token);
    }
}
