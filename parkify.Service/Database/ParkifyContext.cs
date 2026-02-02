using Microsoft.EntityFrameworkCore;

namespace parkify.Service.Database
{
    public class ParkifyContext : DbContext
    {
        public ParkifyContext(DbContextOptions<ParkifyContext> options)
            : base(options)
        {
        }

        public DbSet<User> Users { get; set; }
        public DbSet<ParkingZone> ParkingZones { get; set; }
        public DbSet<ParkingSpot> ParkingSpots { get; set; }
        public DbSet<Reservation> Reservations { get; set; }
        public DbSet<Payment> Payments { get; set; }
        public DbSet<Notification> Notifications { get; set; }
        public DbSet<Review> Reviews { get; set; }
        public DbSet<Preference> Preference { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

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
                .Property(p => p.City)
                .IsRequired()
                .HasMaxLength(100);

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
                .HasOne(ps => ps.ParkingZone)
                .WithMany(pz => pz.Spots)
                .HasForeignKey(ps => ps.ParkingZoneId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Reservation>()
                .HasKey(r => r.Id);

            modelBuilder.Entity<Reservation>()
                .HasIndex(r => r.ReservationCode)
                .IsUnique();

            modelBuilder.Entity<Reservation>()
                .Property(r => r.ReservationCode)
                .IsRequired()
                .HasMaxLength(50);

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
                .Property(p => p.Currency)
                .IsRequired()
                .HasMaxLength(3);

            modelBuilder.Entity<Notification>()
                .HasKey(n => n.Id);

            modelBuilder.Entity<Notification>()
                .Property(n => n.Title)
                .IsRequired()
                .HasMaxLength(200);

            modelBuilder.Entity<Notification>()
                .Property(n => n.Message)
                .IsRequired();

            modelBuilder.Entity<Review>()
                .HasKey(r => r.Id);

            modelBuilder.Entity<Review>()
                .Property(r => r.ReviewText)
                .IsRequired();

            modelBuilder.Entity<Review>()
                .Property(r => r.Rating)
                .IsRequired();

            modelBuilder.Entity<Preference>()
                .HasKey(p => p.Id);

            modelBuilder.Entity<Preference>()
                .Property(p => p.PreferredCity)
                .HasMaxLength(100);

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