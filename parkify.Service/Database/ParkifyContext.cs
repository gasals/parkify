using Microsoft.EntityFrameworkCore;
using parkify.Model.Models;

namespace parkify.Service.Database
{
    public class ParkifyContext : DbContext
    {
        public ParkifyContext(DbContextOptions<ParkifyContext> options)
            : base(options)
        {
        }

        public DbSet<City> Cities { get; set; }
        public DbSet<User> Users { get; set; }
        public DbSet<ParkingZone> ParkingZones { get; set; }
        public DbSet<ParkingSpot> ParkingSpots { get; set; }
        public DbSet<Reservation> Reservations { get; set; }
        public DbSet<Payment> Payments { get; set; }
        public DbSet<Notification> Notifications { get; set; }
        public DbSet<Review> Reviews { get; set; }
        public DbSet<Preference> Preferences { get; set; }
        public DbSet<Vehicle> Vehicles { get; set; }
        public DbSet<Wallet> Wallets { get; set; }
        public DbSet<WalletTransaction> WalletTransactions { get; set; }


        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            modelBuilder.Entity<City>()
                .HasKey(u => u.Id);

            modelBuilder.Entity<City>()
                .HasIndex(u => u.Name)
                .IsUnique();

            modelBuilder.Entity<User>()
                .HasKey(u => u.Id);

            modelBuilder.Entity<User>()
                .HasIndex(u => u.Username)
                .IsUnique();

            modelBuilder.Entity<User>()
                .HasIndex(u => u.Email)
                .IsUnique();

            modelBuilder.Entity<User>()
                .Property(u => u.Username)
                .IsRequired()
                .HasMaxLength(50);

            modelBuilder.Entity<User>()
                .Property(u => u.Email)
                .IsRequired()
                .HasMaxLength(100);

            modelBuilder.Entity<User>()
                .Property(u => u.PasswordHash)
                .IsRequired();

            modelBuilder.Entity<User>()
                .Property(u => u.PasswordSalt)
                .IsRequired();

            modelBuilder.Entity<User>()
                .Property(u => u.CityId)
                .IsRequired(false);

            modelBuilder.Entity<User>()
                .HasOne(u => u.City)
                .WithMany(c => c.Users)
                .HasForeignKey(u => u.CityId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<ParkingZone>()
                .HasKey(p => p.Id);

            modelBuilder.Entity<ParkingZone>()
                .Property(p => p.Name)
                .IsRequired()
                .HasMaxLength(100);

            modelBuilder.Entity<ParkingZone>()
                .Property(p => p.Address)
                .IsRequired()
                .HasMaxLength(200);

            modelBuilder.Entity<ParkingZone>()
                .Property(p => p.CityId)
                .IsRequired();

            modelBuilder.Entity<ParkingZone>()
                .HasOne(p => p.City)
                .WithMany(c => c.ParkingZones)
                .HasForeignKey(p => p.CityId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<ParkingSpot>()
                .HasKey(p => p.Id);

            modelBuilder.Entity<ParkingSpot>()
                .HasIndex(p => p.SpotCode)
                .IsUnique();

            modelBuilder.Entity<ParkingSpot>()
                .Property(p => p.SpotCode)
                .IsRequired()
                .HasMaxLength(50);

            modelBuilder.Entity<ParkingSpot>()
                .HasOne(p => p.ParkingZone)
                .WithMany(z => z.Spots)
                .HasForeignKey(p => p.ParkingZoneId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Reservation>()
                .HasKey(r => r.Id);

            modelBuilder.Entity<Reservation>()
                .HasIndex(r => r.ReservationCode)
                .IsUnique();

            modelBuilder.Entity<Reservation>()
                .HasIndex(r => new { r.UserId, r.ReservationStart, r.ReservationEnd, r.Status });

            modelBuilder.Entity<Reservation>()
                .Property(r => r.ReservationCode)
                .IsRequired()
                .HasMaxLength(50);

            modelBuilder.Entity<Reservation>()
                .Property(r => r.CalculatedPrice)
                .HasPrecision(10, 2);

            modelBuilder.Entity<Reservation>()
                .Property(r => r.FinalPrice)
                .HasPrecision(10, 2);

            modelBuilder.Entity<Reservation>()
                .Property(r => r.WalletAmountUsed)
                .HasPrecision(10, 2);

            modelBuilder.Entity<Reservation>()
                .Property(r => r.PaymentAmountPaid)
                .HasPrecision(10, 2);

            modelBuilder.Entity<Reservation>()
                .HasOne(r => r.User)
                .WithMany(u => u.Reservations)
                .HasForeignKey(r => r.UserId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Reservation>()
                .HasOne(r => r.ParkingZone)
                .WithMany(z => z.Reservations)
                .HasForeignKey(r => r.ParkingZoneId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Reservation>()
                .HasOne(r => r.ParkingSpot)
                .WithMany(s => s.Reservations)
                .HasForeignKey(r => r.ParkingSpotId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Payment>()
                .HasKey(p => p.Id);

            modelBuilder.Entity<Payment>()
                .HasIndex(p => p.PaymentCode)
                .IsUnique();

            modelBuilder.Entity<Payment>()
                .Property(p => p.PaymentCode)
                .IsRequired()
                .HasMaxLength(50);

            modelBuilder.Entity<Payment>()
                .Property(p => p.Amount)
                .HasPrecision(10, 2);

            modelBuilder.Entity<Payment>()
                .HasOne(p => p.User)
                .WithMany(u => u.Payments)
                .HasForeignKey(p => p.UserId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Payment>()
                .HasOne(p => p.Reservation)
                .WithMany(r => r.Payments)
                .HasForeignKey(p => p.ReservationId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Payment>()
                .HasOne(p => p.Wallet)
                .WithMany(w => w.Payments)
                .HasForeignKey(p => p.WalletId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Notification>()
                .HasKey(n => n.Id);

            modelBuilder.Entity<Notification>()
                .Property(n => n.Title)
                .IsRequired()
                .HasMaxLength(200);

            modelBuilder.Entity<Notification>()
                .Property(n => n.Message)
                .IsRequired();

            modelBuilder.Entity<Notification>()
                .HasOne(n => n.User)
                .WithMany(u => u.Notifications)
                .HasForeignKey(n => n.UserId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Notification>()
                .HasOne(n => n.Reservation)
                .WithMany(r => r.Notifications)
                .HasForeignKey(n => n.ReservationId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Notification>()
                .HasOne(n => n.ParkingZone)
                .WithMany(z => z.Notifications)
                .HasForeignKey(n => n.ParkingZoneId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Review>()
                .HasKey(r => r.Id);

            modelBuilder.Entity<Review>()
                .Property(r => r.ReviewText)
                .IsRequired();

            modelBuilder.Entity<Review>()
                .Property(r => r.Rating)
                .IsRequired();

            modelBuilder.Entity<Review>()
                .HasOne(r => r.User)
                .WithMany(u => u.Reviews)
                .HasForeignKey(r => r.UserId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Review>()
                .HasOne(r => r.ParkingZone)
                .WithMany(z => z.Reviews)
                .HasForeignKey(r => r.ParkingZoneId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Preference>()
                .HasKey(p => p.Id);

            modelBuilder.Entity<Preference>()
                .Property(p => p.PreferredCityId)
                .IsRequired(false);

            modelBuilder.Entity<Preference>()
                .HasIndex(p => p.UserId)
                .IsUnique();

            modelBuilder.Entity<Preference>()
                .HasOne(p => p.User)
                .WithOne(u => u.Preference)
                .HasForeignKey<Preference>(p => p.UserId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Preference>()
                .HasOne(p => p.PreferredCity)
                .WithMany(c => c.Preferences)
                .HasForeignKey(p => p.PreferredCityId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Preference>()
                .HasOne(p => p.FavoriteParkingZone)
                .WithMany(z => z.FavoriteByPreferences)
                .HasForeignKey(p => p.FavoriteParkingZoneId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Vehicle>()
                .HasKey(r => r.Id);

            modelBuilder.Entity<Vehicle>()
                .Property(r => r.UserId)
                .IsRequired();

            modelBuilder.Entity<Vehicle>()
                .Property(r => r.LicensePlate)
                .IsRequired();

            modelBuilder.Entity<Vehicle>()
                .Property(r => r.Category)
                .IsRequired();

            modelBuilder.Entity<Vehicle>()
                .HasOne(v => v.User)
                .WithMany(u => u.Vehicles)
                .HasForeignKey(v => v.UserId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Wallet>()
                .HasKey(r => r.Id);

            modelBuilder.Entity<Wallet>()
                .Property(r => r.UserId)
                .IsRequired();

            modelBuilder.Entity<Wallet>()
                .Property(r => r.Balance)
                .HasPrecision(10, 2);

            modelBuilder.Entity<Wallet>()
                .HasIndex(w => w.UserId)
                .IsUnique();

            modelBuilder.Entity<Wallet>()
                .HasOne(w => w.User)
                .WithOne(u => u.Wallet)
                .HasForeignKey<Wallet>(w => w.UserId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<WalletTransaction>()
                .HasKey(r => r.Id);

            modelBuilder.Entity<WalletTransaction>()
                .Property(r => r.WalletId)
                .IsRequired();

            modelBuilder.Entity<WalletTransaction>()
                .Property(r => r.Amount)
                .HasPrecision(10, 2);

            modelBuilder.Entity<WalletTransaction>()
                .HasOne(wt => wt.Wallet)
                .WithMany(w => w.Transactions)
                .HasForeignKey(wt => wt.WalletId)
                .OnDelete(DeleteBehavior.Restrict);


            modelBuilder.Entity<ParkingZone>()
                .Property(p => p.PricePerHour)
                .HasPrecision(10, 2);

            modelBuilder.Entity<ParkingZone>()
                .Property(p => p.DailyRate)
                .HasPrecision(10, 2);

            modelBuilder.Entity<Payment>()
                .Property(p => p.Amount)
                .HasPrecision(10, 2);

            modelBuilder.Entity<Reservation>()
                .Property(r => r.CalculatedPrice)
                .HasPrecision(10, 2);

            modelBuilder.Entity<Reservation>()
                .Property(r => r.DiscountAmount)
                .HasPrecision(10, 2);

            modelBuilder.Entity<Reservation>()
                .Property(r => r.FinalPrice)
                .HasPrecision(10, 2);
        }
    }
}
