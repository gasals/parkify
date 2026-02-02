using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace parkify.Service.Migrations
{
    /// <inheritdoc />
    public partial class UserChanges : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Preference_ParkingZones_FavoriteParkingZoneId",
                table: "Preference");

            migrationBuilder.DropIndex(
                name: "IX_Preference_UserId",
                table: "Preference");

            migrationBuilder.CreateIndex(
                name: "IX_Preference_UserId",
                table: "Preference",
                column: "UserId");

            migrationBuilder.AddForeignKey(
                name: "FK_Preference_ParkingZones_FavoriteParkingZoneId",
                table: "Preference",
                column: "FavoriteParkingZoneId",
                principalTable: "ParkingZones",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Preference_ParkingZones_FavoriteParkingZoneId",
                table: "Preference");

            migrationBuilder.DropIndex(
                name: "IX_Preference_UserId",
                table: "Preference");

            migrationBuilder.CreateIndex(
                name: "IX_Preference_UserId",
                table: "Preference",
                column: "UserId",
                unique: true);

            migrationBuilder.AddForeignKey(
                name: "FK_Preference_ParkingZones_FavoriteParkingZoneId",
                table: "Preference",
                column: "FavoriteParkingZoneId",
                principalTable: "ParkingZones",
                principalColumn: "Id");
        }
    }
}
