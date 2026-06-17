using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using parkify.Model.Constants;
using parkify.Model.Helpers;
using parkify.Model.Models;
using parkify.Model.Requests;
using parkify.Model.SearchObject;
using parkify.Service.Interfaces;
using System.Security.Claims;

namespace parkify.API.Controllers
{
    public class UsersController : BaseCRUDController<User, UserSearch, UserInsertRequest, UserUpdateRequest>
    {
        private readonly IAuthTokenService _authTokenService;
        private readonly ITokenRevocationService _tokenRevocationService;

        public UsersController(
            IUserService service,
            IAuthTokenService authTokenService,
            ITokenRevocationService tokenRevocationService) : base(service)
        {
            _authTokenService = authTokenService;
            _tokenRevocationService = tokenRevocationService;
        }

        [HttpPost("login")]
        [AllowAnonymous]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            if (string.IsNullOrWhiteSpace(request?.Username) || string.IsNullOrWhiteSpace(request.Password))
            {
                return BadRequest(new { error = "Username i lozinka su obavezni." });
            }

            var user = await (_service as IUserService)!.Login(request.Username, request.Password);

            if (user == null)
            {
                return Unauthorized(new { error = "Pogrešan username ili lozinka." });
            }

            return Ok(_authTokenService.CreateAuthResponse(user));
        }

        [HttpPost]
        [Authorize(Roles = AppRoles.Admin)]
        public override async Task<User> Insert([FromBody] UserInsertRequest request)
        {
            return await base.Insert(request);
        }

        [HttpPut("{id}")]
        public override async Task<User> Update(int id, [FromBody] UserUpdateRequest request)
        {
            if (!CanAccessUser(id))
                throw new UnauthorizedAccessException("Nemate pravo izmjene ovog korisnika.");

            return await base.Update(id, request);
        }

        [HttpGet("{id}")]
        public override async Task<User?> GetById(int id)
        {
            if (!CanAccessUser(id))
                throw new UnauthorizedAccessException("Nemate pravo pristupa ovom korisniku.");

            return await base.GetById(id);
        }

        [HttpPost("register")]
        [AllowAnonymous]
        public async Task<IActionResult> Register([FromBody] UserInsertRequest request)
        {
            var user = await (_service as IUserService)!.Insert(request);

            if (user == null)
            {
                return BadRequest(new { error = "Registracija nije uspjela." });
            }

            return Ok(_authTokenService.CreateAuthResponse(user));
        }

        [HttpPost("logout")]
        [Authorize]
        public IActionResult Logout()
        {
            _tokenRevocationService.RevokeCurrentToken();

            return Ok(new { message = "Uspješno ste odjavljeni." });
        }

        [HttpGet]
        [Authorize(Roles = AppRoles.Admin)]
        public override async Task<PagedResult<User>> GetList([FromQuery] UserSearch searchObject)
        {
            return await base.GetList(searchObject);
        }

        private bool CanAccessUser(int targetUserId)
        {
            if (User.IsInRole(AppRoles.Admin))
                return true;

            var claimValue = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return int.TryParse(claimValue, out var currentUserId) && currentUserId == targetUserId;
        }
    }
}