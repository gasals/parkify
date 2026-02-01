using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace parkify.Service.Migrations
{
    /// <inheritdoc />
    public partial class CreatedModified : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "RegistrationDate",
                table: "Users",
                newName: "Created");

            migrationBuilder.RenameColumn(
                name: "CreatedDate",
                table: "Reviews",
                newName: "Created");

            migrationBuilder.RenameColumn(
                name: "UpdatedDate",
                table: "Reservations",
                newName: "Modified");

            migrationBuilder.RenameColumn(
                name: "CreatedDate",
                table: "Reservations",
                newName: "Created");

            migrationBuilder.RenameColumn(
                name: "CreatedDate",
                table: "Preference",
                newName: "Created");

            migrationBuilder.RenameColumn(
                name: "RefundedDate",
                table: "Payments",
                newName: "Refunded");

            migrationBuilder.RenameColumn(
                name: "CreatedDate",
                table: "Payments",
                newName: "Created");

            migrationBuilder.RenameColumn(
                name: "CompletedDate",
                table: "Payments",
                newName: "Modified");

            migrationBuilder.RenameColumn(
                name: "UpdatedDate",
                table: "ParkingZones",
                newName: "Modified");

            migrationBuilder.RenameColumn(
                name: "CreatedDate",
                table: "ParkingZones",
                newName: "Created");

            migrationBuilder.RenameColumn(
                name: "CreatedDate",
                table: "ParkingSpots",
                newName: "Created");

            migrationBuilder.RenameColumn(
                name: "CreatedDate",
                table: "Notifications",
                newName: "Created");

            migrationBuilder.AddColumn<DateTime>(
                name: "Modified",
                table: "Users",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "Modified",
                table: "Reviews",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "Modified",
                table: "Preference",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "Completed",
                table: "Payments",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "Modified",
                table: "ParkingSpots",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "Modified",
                table: "Notifications",
                type: "datetime2",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Modified",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "Modified",
                table: "Reviews");

            migrationBuilder.DropColumn(
                name: "Modified",
                table: "Preference");

            migrationBuilder.DropColumn(
                name: "Completed",
                table: "Payments");

            migrationBuilder.DropColumn(
                name: "Modified",
                table: "ParkingSpots");

            migrationBuilder.DropColumn(
                name: "Modified",
                table: "Notifications");

            migrationBuilder.RenameColumn(
                name: "Created",
                table: "Users",
                newName: "RegistrationDate");

            migrationBuilder.RenameColumn(
                name: "Created",
                table: "Reviews",
                newName: "CreatedDate");

            migrationBuilder.RenameColumn(
                name: "Modified",
                table: "Reservations",
                newName: "UpdatedDate");

            migrationBuilder.RenameColumn(
                name: "Created",
                table: "Reservations",
                newName: "CreatedDate");

            migrationBuilder.RenameColumn(
                name: "Created",
                table: "Preference",
                newName: "CreatedDate");

            migrationBuilder.RenameColumn(
                name: "Refunded",
                table: "Payments",
                newName: "RefundedDate");

            migrationBuilder.RenameColumn(
                name: "Modified",
                table: "Payments",
                newName: "CompletedDate");

            migrationBuilder.RenameColumn(
                name: "Created",
                table: "Payments",
                newName: "CreatedDate");

            migrationBuilder.RenameColumn(
                name: "Modified",
                table: "ParkingZones",
                newName: "UpdatedDate");

            migrationBuilder.RenameColumn(
                name: "Created",
                table: "ParkingZones",
                newName: "CreatedDate");

            migrationBuilder.RenameColumn(
                name: "Created",
                table: "ParkingSpots",
                newName: "CreatedDate");

            migrationBuilder.RenameColumn(
                name: "Created",
                table: "Notifications",
                newName: "CreatedDate");
        }
    }
}
