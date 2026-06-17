using parkify.Model.Models;
using parkify.Model.Requests;
using parkify.Model.SearchObject;

namespace parkify.Service.Interfaces
{
    public interface IUserService : ICRUDService<User, UserSearch, UserInsertRequest, UserUpdateRequest>
    {
        Task<User?> Login(string username, string password);
        Task<User?> GetLoggedInUser(string username);
        Task<User> Delete(int id);
    }
}
