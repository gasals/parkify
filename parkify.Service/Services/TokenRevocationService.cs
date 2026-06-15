using Microsoft.Extensions.Caching.Memory;
using Microsoft.AspNetCore.Http;
using parkify.Model.Exceptions;
using parkify.Service.Interfaces;

namespace parkify.Service.Services
{
    public class TokenRevocationService : ITokenRevocationService
    {
        private readonly IMemoryCache _cache;
        private readonly IHttpContextAccessor _httpContextAccessor;

        public TokenRevocationService(IMemoryCache cache, IHttpContextAccessor httpContextAccessor)
        {
            _cache = cache;
            _httpContextAccessor = httpContextAccessor;
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

        public void RevokeCurrentToken()
        {
            var httpContext = _httpContextAccessor.HttpContext;
            var rawAuthHeader = httpContext?.Request.Headers.Authorization.ToString() ?? string.Empty;

            if (!rawAuthHeader.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase))
                throw new BusinessException("Authorization header nije validan.");

            var token = rawAuthHeader[7..].Trim();
            if (string.IsNullOrWhiteSpace(token))
                throw new BusinessException("Token nije pronađen.");

            var expiresAtUtc = DateTime.UtcNow.AddDays(7);
            var expClaim = httpContext?.User.FindFirst("exp")?.Value;
            if (long.TryParse(expClaim, out var expUnix))
            {
                expiresAtUtc = DateTimeOffset.FromUnixTimeSeconds(expUnix).UtcDateTime;
            }

            RevokeToken(token, expiresAtUtc);
        }

        private static string GetCacheKey(string token)
        {
            return $"revoked_token:{token}";
        }
    }
}
