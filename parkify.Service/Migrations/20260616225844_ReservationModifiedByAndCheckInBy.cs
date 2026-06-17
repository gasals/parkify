using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace parkify.Service.Migrations
{
    public partial class ReservationModifiedByAndCheckInBy : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Reservations_UserId",
                table: "Reservations");

            migrationBuilder.AddColumn<int>(
                name: "CheckInBy",
                table: "Reservations",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "ModifiedBy",
                table: "Reservations",
                type: "int",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Reservations_UserId_ReservationStart_ReservationEnd_Status",
                table: "Reservations",
                columns: new[] { "UserId", "ReservationStart", "ReservationEnd", "Status" });
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Reservations_UserId_ReservationStart_ReservationEnd_Status",
                table: "Reservations");

            migrationBuilder.DropColumn(
                name: "CheckInBy",
                table: "Reservations");

            migrationBuilder.DropColumn(
                name: "ModifiedBy",
                table: "Reservations");

            migrationBuilder.CreateIndex(
                name: "IX_Reservations_UserId",
                table: "Reservations",
                column: "UserId");
        }
    }
}
