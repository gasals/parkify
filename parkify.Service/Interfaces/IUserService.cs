using parkify.Model.Models;
using parkify.Model.Requests;
using parkify.Model.SearchObject;

namespace parkify.Service.Interfaces
{
    public interface IUserService : ICRUDService<User, UserSearch, UserInsertRequest, UserUpdateRequest>
    {
        User Login(string username, string password);
        User GetLoggedInUser(string username);
        User Delete(int id);
    }
}
