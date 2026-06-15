using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace parkify.Service.Migrations
{
    /// <inheritdoc />
    public partial class VehicleCategoryInt : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "CategoryTemp",
                table: "Vehicles",
                type: "int",
                nullable: true);

            migrationBuilder.Sql(@"
                UPDATE Vehicles
                SET CategoryTemp = CASE UPPER(REPLACE(LTRIM(RTRIM(Category)), ' ', ''))
                    WHEN 'AM' THEN 1
                    WHEN 'A1' THEN 2
                    WHEN 'A2' THEN 3
                    WHEN 'A' THEN 4
                    WHEN 'B' THEN 5
                    WHEN 'BE' THEN 6
                    WHEN 'C1' THEN 7
                    WHEN 'C1E' THEN 8
                    WHEN 'C' THEN 9
                    WHEN 'CE' THEN 10
                    WHEN 'D1' THEN 11
                    WHEN 'D1E' THEN 12
                    WHEN 'D' THEN 13
                    WHEN 'DE' THEN 14
                    WHEN 'F' THEN 15
                    WHEN 'G' THEN 16
                    WHEN 'H' THEN 17
                    ELSE 5
                END
            ");

            migrationBuilder.DropColumn(
                name: "Category",
                table: "Vehicles");

            migrationBuilder.RenameColumn(
                name: "CategoryTemp",
                table: "Vehicles",
                newName: "Category");

            migrationBuilder.AlterColumn<int>(
                name: "Category",
                table: "Vehicles",
                type: "int",
                nullable: false,
                oldClrType: typeof(int),
                oldType: "int",
                oldNullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "CategoryTemp",
                table: "Vehicles",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "B");

            migrationBuilder.Sql(@"
                UPDATE Vehicles
                SET CategoryTemp = CASE Category
                    WHEN 1 THEN 'AM'
                    WHEN 2 THEN 'A1'
                    WHEN 3 THEN 'A2'
                    WHEN 4 THEN 'A'
                    WHEN 5 THEN 'B'
                    WHEN 6 THEN 'BE'
                    WHEN 7 THEN 'C1'
                    WHEN 8 THEN 'C1E'
                    WHEN 9 THEN 'C'
                    WHEN 10 THEN 'CE'
                    WHEN 11 THEN 'D1'
                    WHEN 12 THEN 'D1E'
                    WHEN 13 THEN 'D'
                    WHEN 14 THEN 'DE'
                    WHEN 15 THEN 'F'
                    WHEN 16 THEN 'G'
                    WHEN 17 THEN 'H'
                    ELSE 'B'
                END
            ");

            migrationBuilder.DropColumn(
                name: "Category",
                table: "Vehicles");

            migrationBuilder.RenameColumn(
                name: "CategoryTemp",
                table: "Vehicles",
                newName: "Category");
        }
    }
}
