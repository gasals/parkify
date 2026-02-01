using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using parkify.Model.Helpers;
using parkify.Model.Models;
using parkify.Model.Requests;
using parkify.Model.SearchObject;
using parkify.Service.Interfaces;

namespace parkify.API.Controllers
{
    public class UsersController : BaseCRUDController<User, UserSearch, UserInsertRequest, UserUpdateRequest>
    {

        public UsersController(IUserService service) : base(service)
        {
        }

        [HttpPost("login")]
        [AllowAnonymous]
        public User? Login(string username, string password)
        {
            return (_service as IUserService)?.Login(username, password);
        }

        [HttpPost("register")]
        [AllowAnonymous]
        public override User Insert([FromBody] UserInsertRequest request)
        {
            return base.Insert(request);
        }

        [HttpGet]
        [AllowAnonymous]
        public override PagedResult<User> GetList([FromQuery] UserSearch searchObject)
        {
            return base.GetList(searchObject);
        }
    }
}