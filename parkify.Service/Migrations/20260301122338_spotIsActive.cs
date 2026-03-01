using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace parkify.Service.Migrations
{
    /// <inheritdoc />
    public partial class spotIsActive : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "CoveredSpots",
                table: "ParkingZones");

            migrationBuilder.AddColumn<bool>(
                name: "IsActive",
                table: "ParkingSpots",
                type: "bit",
                nullable: false,
                defaultValue: false);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "IsActive",
                table: "ParkingSpots");

            migrationBuilder.AddColumn<int>(
                name: "CoveredSpots",
                table: "ParkingZones",
                type: "int",
                nullable: false,
                defaultValue: 0);
        }
    }
}
