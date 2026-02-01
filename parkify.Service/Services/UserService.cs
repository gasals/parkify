using MapsterMapper;
using parkify.Model.Models;
using parkify.Model.Requests;
using parkify.Model.SearchObject;
using parkify.Service.Interfaces;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using System.Globalization;

namespace parkify.Service.Services
{
    public class UserService
        : BaseCRUDService<User, UserSearch, Database.User, UserInsertRequest, UserUpdateRequest>,
          IUserService
    {
        public UserService(Database.ParkifyContext context, IMapper mapper)
            : base(context, mapper)
        {
        }

        #region Filters
        public override IQueryable<Database.User> AddFilter(UserSearch search, IQueryable<Database.User> query)
        {
            query = base.AddFilter(search, query);

            if (!string.IsNullOrWhiteSpace(search?.Username))
            {
                query = query.Where(x => x.Username.Contains(search.Username));
            }

            if (!string.IsNullOrWhiteSpace(search?.Email))
            {
                query = query.Where(x => x.Email == search.Email);
            }

            if (!string.IsNullOrWhiteSpace(search?.FirstName))
            {
                query = query.Where(x => x.FirstName == search.FirstName);
            }

            if (!string.IsNullOrWhiteSpace(search?.LastName))
            {
                query = query.Where(x => x.LastName == search.LastName);
            }

            return query;
        }
        #endregion

        #region Insert / Update
        public override void BeforeInsert(UserInsertRequest request, Database.User entity)
        {
            if (request.Password != request.PasswordConfirm)
                throw new Exception("Lozinka i potvrda lozinke se ne podudaraju.");

            if (!IsValidEmail(request.Email))
                throw new Exception("Email nije u validnom formatu.");

            if (Context.Users.Any(x => x.Username == request.Username))
                throw new Exception("Korisničko ime je zauzeto.");

            if (Context.Users.Any(x => x.Email == request.Email))
                throw new Exception("Email je već u upotrebi.");

            entity.PasswordSalt = GenerateSalt();
            entity.PasswordHash = GenerateHash(entity.PasswordSalt, request.Password);

            base.BeforeInsert(request, entity);
        }

        public override void BeforeUpdate(UserUpdateRequest request, Database.User entity)
        {
            if (!string.IsNullOrWhiteSpace(request.Password))
            {
                if (request.Password != request.PasswordConfirm)
                    throw new Exception("Lozinka i potvrda lozinke se ne podudaraju.");

                entity.PasswordSalt = GenerateSalt();
                entity.PasswordHash = GenerateHash(entity.PasswordSalt, request.Password);
            }

            if (!IsValidEmail(request.Email))
                throw new Exception("Email nije u validnom formatu.");

            var emailExists = Context.Users
                .Any(x => x.Email == request.Email && x.Id != entity.Id);

            if (emailExists)
                throw new Exception("Email je već zauzet.");

            base.BeforeUpdate(request, entity);
        }
        #endregion

        #region Auth
        public User Login(string username, string password)
        {
            var entity = Context.Users
                .FirstOrDefault(x => x.Username == username);

            if (entity == null)
                return null;

            var hash = GenerateHash(entity.PasswordSalt, password);

            if (hash != entity.PasswordHash)
                return null;

            return Mapper.Map<User>(entity);
        }
        public User GetLoggedInUser(string username)
        {
            var entity = Context.Users
                .FirstOrDefault(x => x.Username == username);

            if (entity == null)
                return null;

            return Mapper.Map<User>(entity);
        }
        #endregion

        #region Get / Delete
        public override User GetById(int id)
        {
            var entity = Context.Users
                .FirstOrDefault(x => x.Id == id);

            if (entity == null)
                return null;

            return Mapper.Map<User>(entity);
        }

        public User Delete(int id)
        {
            var entity = Context.Users.FirstOrDefault(x => x.Id == id);

            if (entity == null)
                throw new Exception("Korisnik sa tim ID-om ne postoji.");

            Context.Users.Remove(entity);
            Context.SaveChanges();

            return Mapper.Map<User>(entity);
        }

        #endregion

        #region Helpers
        public static string GenerateSalt()
        {
            var bytes = RandomNumberGenerator.GetBytes(16);
            return Convert.ToBase64String(bytes);
        }

        public static string GenerateHash(string salt, string password)
        {
            var saltBytes = Convert.FromBase64String(salt);
            var passwordBytes = Encoding.Unicode.GetBytes(password);

            var combined = new byte[saltBytes.Length + passwordBytes.Length];
            Buffer.BlockCopy(saltBytes, 0, combined, 0, saltBytes.Length);
            Buffer.BlockCopy(passwordBytes, 0, combined, saltBytes.Length, passwordBytes.Length);

            using var algorithm = SHA1.Create();
            return Convert.ToBase64String(algorithm.ComputeHash(combined));
        }

        public static bool IsValidEmail(string email)
        {
            if (string.IsNullOrWhiteSpace(email))
                return false;

            try
            {
                email = Regex.Replace(email, @"(@)(.+)$", match =>
                {
                    var idn = new IdnMapping();
                    var domainName = idn.GetAscii(match.Groups[2].Value);
                    return match.Groups[1].Value + domainName;
                });

                return Regex.IsMatch(
                    email,
                    @"^[^@\s]+@[^@\s]+\.[^@\s]+$",
                    RegexOptions.IgnoreCase);
            }
            catch
            {
                return false;
            }
        }
        #endregion
    }
}
