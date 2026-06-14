using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using parkify.Model.Helpers;
using parkify.Model.Models;
using parkify.Model.Requests;
using parkify.Model.SearchObject;
using parkify.Service.Interfaces;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace parkify.API.Controllers
{
    public class UsersController : BaseCRUDController<User, UserSearch, UserInsertRequest, UserUpdateRequest>
    {
        private readonly IConfiguration _configuration;
        public UsersController(IUserService service, IConfiguration configuration) : base(service)
        {
            _configuration = configuration;
        }

        [HttpPost("login")]
        [AllowAnonymous]
        public IActionResult Login([FromBody] LoginRequest request)
        {
            if (string.IsNullOrWhiteSpace(request?.Username) || string.IsNullOrWhiteSpace(request.Password))
            {
                return BadRequest(new { error = "Username i lozinka su obavezni." });
            }

            var user = (_service as IUserService)?.Login(request.Username, request.Password);

            if (user == null)
            {
                return Unauthorized(new { error = "Pogrešan username ili lozinka." });
            }

            return Ok(CreateAuthResponse(user));
        }

        [HttpPost]
        [Authorize(Roles = "Admin")]
        public override User Insert([FromBody] UserInsertRequest request)
        {
            return base.Insert(request);
        }

        [HttpPut("{id}")]
        public override User Update(int id, [FromBody] UserUpdateRequest request)
        {
            if (!CanAccessUser(id))
                throw new UnauthorizedAccessException("Nemate pravo izmjene ovog korisnika.");

            return base.Update(id, request);
        }

        [HttpGet("{id}")]
        public override User GetById(int id)
        {
            if (!CanAccessUser(id))
                throw new UnauthorizedAccessException("Nemate pravo pristupa ovom korisniku.");

            return base.GetById(id);
        }

        [HttpPost("register")]
        [AllowAnonymous]
        public IActionResult Register([FromBody] UserInsertRequest request)
        {
            var user = (_service as IUserService)?.Insert(request);

            if (user == null)
            {
                return BadRequest(new { error = "Registracija nije uspjela." });
            }

            return Ok(CreateAuthResponse(user));
        }

        private object CreateAuthResponse(User user)
        {
            string role = user.IsAdmin ? "Admin" : "User";

            var tokenHandler = new JwtSecurityTokenHandler();
            var key = Encoding.ASCII.GetBytes(_configuration["Jwt:Key"]);

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
            var tokenString = tokenHandler.WriteToken(token);

            return new
            {
                Token = tokenString,
                user.Id,
                user.IsAdmin,
                user.IsActive
            };
        }

        [HttpGet]
        [Authorize(Roles = "Admin")]
        public override PagedResult<User> GetList([FromQuery] UserSearch searchObject)
        {
            return base.GetList(searchObject);
        }

        private bool CanAccessUser(int targetUserId)
        {
            if (User.IsInRole("Admin"))
                return true;

            var claimValue = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return int.TryParse(claimValue, out var currentUserId) && currentUserId == targetUserId;
        }
    }
}