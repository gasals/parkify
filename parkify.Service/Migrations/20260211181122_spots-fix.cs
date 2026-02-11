using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace parkify.Service.Migrations
{
    /// <inheritdoc />
    public partial class spotsfix : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_ParkingSpots_ParkingZones_ParkingZoneId",
                table: "ParkingSpots");

            migrationBuilder.AddForeignKey(
                name: "FK_ParkingSpots_ParkingZones_ParkingZoneId",
                table: "ParkingSpots",
                column: "ParkingZoneId",
                principalTable: "ParkingZones",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_ParkingSpots_ParkingZones_ParkingZoneId",
                table: "ParkingSpots");

            migrationBuilder.AddForeignKey(
                name: "FK_ParkingSpots_ParkingZones_ParkingZoneId",
                table: "ParkingSpots",
                column: "ParkingZoneId",
                principalTable: "ParkingZones",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }
    }
}
