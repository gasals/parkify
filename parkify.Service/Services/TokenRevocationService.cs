using Microsoft.Extensions.Caching.Memory;
using parkify.Service.Interfaces;

namespace parkify.Service.Services
{
    public class TokenRevocationService : ITokenRevocationService
    {
        private readonly IMemoryCache _cache;

        public TokenRevocationService(IMemoryCache cache)
        {
            _cache = cache;
        }

        public void RevokeToken(string token, DateTime expiresAtUtc)
        {
            if (string.IsNullOrWhiteSpace(token))
                return;

            var ttl = expiresAtUtc - DateTime.UtcNow;
            if (ttl <= TimeSpan.Zero)
                ttl = TimeSpan.FromMinutes(1);

            _cache.Set(GetCacheKey(token), true, ttl);
        }

        public bool IsTokenRevoked(string token)
        {
            if (string.IsNullOrWhiteSpace(token))
                return false;

            return _cache.TryGetValue(GetCacheKey(token), out bool _);
        }

        private static string GetCacheKey(string token)
        {
            return $"revoked_token:{token}";
        }
    }
}
