using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using parkify.Model.Exceptions;
using parkify.Model.Models;
using parkify.Model.Requests;
using parkify.Model.SearchObject;
using parkify.Service.Interfaces;
using System.Globalization;
using System.Security.Cryptography;
using System.Text.RegularExpressions;

namespace parkify.Service.Services
{
    public class UserService
        : BaseCRUDService<User, UserSearch, Database.User, UserInsertRequest, UserUpdateRequest>,
          IUserService
    {
        private const int Pbkdf2Iterations = 100_000;
        private const int Pbkdf2KeySize = 32;

        public UserService(Database.ParkifyContext context, IMapper mapper)
            : base(context, mapper)
        {
        }

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

            if (search?.CityId.HasValue == true)
            {
                query = query.Where(x => x.CityId == search.CityId);
            }

            return query;
        }

        public override async Task BeforeInsert(UserInsertRequest request, Database.User entity)
        {
            if (request.Password != request.PasswordConfirm)
                throw new UserException("Lozinka i potvrda lozinke se ne podudaraju.");

            if (!IsValidEmail(request.Email))
                throw new UserException("Email nije u validnom formatu.");

            if (await Context.Users.AnyAsync(x => x.Username == request.Username))
                throw new UserException("Korisničko ime je zauzeto.");

            if (await Context.Users.AnyAsync(x => x.Email == request.Email))
                throw new UserException("Email je već u upotrebi.");

            if (request.CityId.HasValue && !await Context.Cities.AnyAsync(x => x.Id == request.CityId.Value))
                throw new UserException("Odabrani grad ne postoji.");

            entity.IsAdmin = false;

            entity.PasswordSalt = GenerateSalt();
            entity.PasswordHash = GenerateHash(entity.PasswordSalt, request.Password);


            await base.BeforeInsert(request, entity);
        }

        public override async Task AfterInsert(Database.User entity, UserInsertRequest request)
        {
            if (!entity.IsAdmin)
            {
                var newWallet = new Database.Wallet
                {
                    UserId = entity.Id,
                    Balance = 0,
                    Created = DateTime.UtcNow
                };
                Context.Wallets.Add(newWallet);
                await Context.SaveChangesAsync();
            }

            await base.AfterInsert(entity, request);
        }

        public override async Task BeforeUpdate(UserUpdateRequest request, Database.User entity)
        {
            if (!string.IsNullOrWhiteSpace(request.Password))
            {
                if (string.IsNullOrWhiteSpace(request.CurrentPassword))
                    throw new UserException("Trenutna lozinka je obavezna.");

                var currentHash = GenerateHash(entity.PasswordSalt, request.CurrentPassword);
                if (currentHash != entity.PasswordHash)
                    throw new UserException("Trenutna lozinka nije ispravna.");

                if (request.Password != request.PasswordConfirm)
                    throw new UserException("Lozinka i potvrda lozinke se ne podudaraju.");

                entity.PasswordSalt = GenerateSalt();
                entity.PasswordHash = GenerateHash(entity.PasswordSalt, request.Password);
            }

            if (!IsValidEmail(request.Email))
                throw new UserException("Email nije u validnom formatu.");

            var emailExists = await Context.Users
                .AnyAsync(x => x.Email == request.Email && x.Id != entity.Id);

            if (emailExists)
                throw new UserException("Email je već zauzet.");

            if (request.CityId.HasValue && !await Context.Cities.AnyAsync(x => x.Id == request.CityId.Value))
                throw new UserException("Odabrani grad ne postoji.");

            await base.BeforeUpdate(request, entity);
        }

        public async Task<User?> Login(string username, string password)
        {
            var entity = await Context.Users
                .FirstOrDefaultAsync(x => x.Username == username);

            if (entity == null)
                return null;

            var hash = GenerateHash(entity.PasswordSalt, password);

            if (hash != entity.PasswordHash)
                return null;

            return Mapper.Map<User>(entity);
        }
        public async Task<User?> GetLoggedInUser(string username)
        {
            var entity = await Context.Users
                .FirstOrDefaultAsync(x => x.Username == username);

            if (entity == null)
                return null;

            return Mapper.Map<User>(entity);
        }
        public override async Task<User?> GetById(int id)
        {
            var entity = await Context.Users
                .FirstOrDefaultAsync(x => x.Id == id);

            if (entity == null)
                return null;

            return Mapper.Map<User>(entity);
        }

        public async Task<User> Delete(int id)
        {
            var entity = await Context.Users.FirstOrDefaultAsync(x => x.Id == id);

            if (entity == null)
                throw new UserException("Korisnik sa tim ID-om ne postoji.");

            Context.Users.Remove(entity);
            await Context.SaveChangesAsync();

            return Mapper.Map<User>(entity);
        }

        public static string GenerateSalt()
        {
            var bytes = RandomNumberGenerator.GetBytes(16);
            return Convert.ToBase64String(bytes);
        }

        public static string GenerateHash(string salt, string password)
        {
            var saltBytes = Convert.FromBase64String(salt);
            var derived = Rfc2898DeriveBytes.Pbkdf2(
                password,
                saltBytes,
                Pbkdf2Iterations,
                HashAlgorithmName.SHA256,
                Pbkdf2KeySize);

            return Convert.ToBase64String(derived);
        }

        public static bool IsValidEmail(string email)
        {
            if (string.IsNullOrWhiteSpace(email))
                return true;

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
    }
}
