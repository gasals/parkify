using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace parkify.Service.Migrations
{
    /// <inheritdoc />
    public partial class AvailableSpots : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "AvailableSpots",
                table: "ParkingZones",
                type: "int",
                nullable: false,
                defaultValue: 0);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "AvailableSpots",
                table: "ParkingZones");
        }
    }
}
