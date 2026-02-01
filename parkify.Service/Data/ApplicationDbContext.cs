using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using parkify.Model.Entities;
using System.Collections.Generic;
using System.Reflection.Emit;

namespace parkify.Service.Data
{
    public class ApplicationDbContext : IdentityDbContext<User>
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
            : base(options)
        {
        }

        public DbSet<ParkingZone> ParkingZones { get; set; }
        public DbSet<ParkingSpot> ParkingSpots { get; set; }
        public DbSet<Reservation> Reservations { get; set; }
        public DbSet<Payment> Payments { get; set; }
        public DbSet<Notification> Notifications { get; set; }
        public DbSet<Review> Review { get; set; }
        public DbSet<Preference> Preference { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // ==================== PARKINGZONE ====================
            modelBuilder.Entity<ParkingZone>()
                .HasKey(p => p.Id);

            modelBuilder.Entity<ParkingZone>()
                .HasMany(p => p.Spots)
                .WithOne(s => s.ParkingZone)
                .HasForeignKey(s => s.ParkingZoneId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<ParkingZone>()
                .HasMany(p => p.Reservations)
                .WithOne(r => r.ParkingZone)
                .HasForeignKey(r => r.ParkingZoneId)
                .OnDelete(DeleteBehavior.Restrict);

            // ==================== PARKINGSPOT ====================
            modelBuilder.Entity<ParkingSpot>()
                .HasKey(p => p.Id);

            modelBuilder.Entity<ParkingSpot>()
                .HasIndex(p => p.SpotCode)
                .IsUnique();

            modelBuilder.Entity<ParkingSpot>()
                .HasMany(p => p.Reservations)
                .WithOne(r => r.ParkingSpot)
                .HasForeignKey(r => r.ParkingSpotId)
                .OnDelete(DeleteBehavior.Restrict);

            // ==================== RESERVATION ====================
            modelBuilder.Entity<Reservation>()
                .HasKey(r => r.Id);

            modelBuilder.Entity<Reservation>()
                .HasIndex(r => r.ReservationCode)
                .IsUnique();

            modelBuilder.Entity<Reservation>()
                .HasOne(r => r.User)
                .WithMany(u => u.Reservations)
                .HasForeignKey(r => r.UserId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Reservation>()
                .HasOne(r => r.Payment)
                .WithOne(p => p.Reservation)
                .HasForeignKey<Payment>(p => p.ReservationId)
                .OnDelete(DeleteBehavior.Restrict);

            // ==================== PAYMENT ====================
            modelBuilder.Entity<Payment>()
                .HasKey(p => p.Id);

            modelBuilder.Entity<Payment>()
                .HasIndex(p => p.PaymentCode)
                .IsUnique();

            modelBuilder.Entity<Payment>()
                .HasOne(p => p.User)
                .WithMany(u => u.Payments)
                .HasForeignKey(p => p.UserId)
                .OnDelete(DeleteBehavior.Restrict);

            // ==================== NOTIFICATION ====================
            modelBuilder.Entity<Notification>()
                .HasKey(n => n.Id);

            modelBuilder.Entity<Notification>()
                .HasOne(n => n.User)
                .WithMany(u => u.Notifications)
                .HasForeignKey(n => n.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            // ==================== REVIEW ====================
            modelBuilder.Entity<Review>()
                .HasKey(r => r.Id);

            modelBuilder.Entity<Review>()
                .HasOne(r => r.User)
                .WithMany(u => u.Reviews)
                .HasForeignKey(r => r.UserId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Review>()
                .HasOne(r => r.ParkingZone)
                .WithMany(pz => pz.Reviews)
                .HasForeignKey(r => r.ParkingZoneId)
                .OnDelete(DeleteBehavior.Cascade);

            // ==================== PREFERENCE ====================
            modelBuilder.Entity<Preference>()
                .HasKey(p => p.Id);

            modelBuilder.Entity<Preference>()
                .HasOne(p => p.User)
                .WithOne(u => u.Preference)
                .HasForeignKey<Preference>(p => p.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            // ==================== DECIMAL PRECISION ====================
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