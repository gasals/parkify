using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using parkify.Model.Constants;
using parkify.Model.Exceptions;
using parkify.Model.Models;
using parkify.Service.Interfaces;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace parkify.Service.Services
{
    public class AuthTokenService : IAuthTokenService
    {
        private readonly IConfiguration _configuration;

        public AuthTokenService(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        public AuthResponse CreateAuthResponse(User user)
        {
            var jwtKey = _configuration["Jwt:Key"];
            if (string.IsNullOrWhiteSpace(jwtKey))
                throw new BusinessException("JWT konfiguracija nije validna.");

            var role = user.IsAdmin ? AppRoles.Admin : AppRoles.User;

            var tokenHandler = new JwtSecurityTokenHandler();
            var key = Encoding.ASCII.GetBytes(jwtKey);

            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(new[]
                {
                    new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
                    new Claim(ClaimTypes.Name, user.Username),
                    new Claim(ClaimTypes.Role, role)
                }),
                Expires = DateTime.UtcNow.AddDays(7),
                Issuer = _configuration["Jwt:Issuer"],
                Audience = _configuration["Jwt:Audience"],
                SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(key), SecurityAlgorithms.HmacSha256Signature)
            };

            var token = tokenHandler.CreateToken(tokenDescriptor);

            return new AuthResponse
            {
                Token = tokenHandler.WriteToken(token),
                Id = user.Id,
                IsAdmin = user.IsAdmin,
                IsActive = user.IsActive
            };
        }
    }
}