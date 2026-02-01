using parkify.Model.SearchObject;
using parkify.Model.Requests;
using parkify.Model.Models;

namespace parkify.Service.Interfaces
{
    public interface IUserService : ICRUDService<User, UserSearch, UserInsertRequest, UserUpdateRequest>
    {
        User Login(string username, string password);
        User GetLoggedInUser(string username);
        User Delete(int id);
    }
}
