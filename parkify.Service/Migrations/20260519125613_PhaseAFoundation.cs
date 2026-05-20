using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace parkify.Service.Migrations
{
    /// <inheritdoc />
    public partial class PhaseAFoundation : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_ParkingSpots_ParkingZones_ParkingZoneId",
                table: "ParkingSpots");

            migrationBuilder.Sql(@"
DELETE p
FROM [Preferences] AS p
LEFT JOIN [Users] AS u ON u.[Id] = p.[UserId]
WHERE p.[UserId] <= 0 OR u.[Id] IS NULL;

WITH RankedPreferences AS
(
    SELECT
        [Id],
        ROW_NUMBER() OVER
        (
            PARTITION BY [UserId]
            ORDER BY COALESCE([Modified], [Created]) DESC, [Id] DESC
        ) AS [RowNumber]
    FROM [Preferences]
)
DELETE FROM [Preferences]
WHERE [Id] IN
(
    SELECT [Id]
    FROM RankedPreferences
    WHERE [RowNumber] > 1
);

UPDATE p
SET [PreferredCityId] = NULL
FROM [Preferences] AS p
LEFT JOIN [Cities] AS c ON c.[Id] = p.[PreferredCityId]
WHERE p.[PreferredCityId] IS NOT NULL AND c.[Id] IS NULL;

UPDATE p
SET [FavoriteParkingZoneId] = NULL
FROM [Preferences] AS p
LEFT JOIN [ParkingZones] AS pz ON pz.[Id] = p.[FavoriteParkingZoneId]
WHERE p.[FavoriteParkingZoneId] IS NOT NULL AND pz.[Id] IS NULL;

IF NOT EXISTS (SELECT 1 FROM [Cities])
BEGIN
    INSERT INTO [Cities] ([Name], [Latitude], [Longitude])
    VALUES (N'Unknown City', 0, 0);
END;

DECLARE @FallbackCityId INT;
SELECT TOP(1) @FallbackCityId = [Id]
FROM [Cities]
ORDER BY [Id];

UPDATE pz
SET [CityId] = @FallbackCityId
FROM [ParkingZones] AS pz
LEFT JOIN [Cities] AS c ON c.[Id] = pz.[CityId]
WHERE c.[Id] IS NULL;

DELETE w
FROM [Wallets] AS w
LEFT JOIN [Users] AS u ON u.[Id] = w.[UserId]
WHERE w.[UserId] <= 0 OR u.[Id] IS NULL;

WITH RankedWallets AS
(
    SELECT
        [Id],
        ROW_NUMBER() OVER
        (
            PARTITION BY [UserId]
            ORDER BY COALESCE([Modified], [Created]) DESC, [Id] DESC
        ) AS [RowNumber]
    FROM [Wallets]
)
DELETE FROM [Wallets]
WHERE [Id] IN
(
    SELECT [Id]
    FROM RankedWallets
    WHERE [RowNumber] > 1
);

DELETE v
FROM [Vehicles] AS v
LEFT JOIN [Users] AS u ON u.[Id] = v.[UserId]
WHERE v.[UserId] <= 0 OR u.[Id] IS NULL;

DELETE r
FROM [Reviews] AS r
LEFT JOIN [Users] AS u ON u.[Id] = r.[UserId]
LEFT JOIN [ParkingZones] AS pz ON pz.[Id] = r.[ParkingZoneId]
WHERE r.[UserId] <= 0 OR u.[Id] IS NULL OR pz.[Id] IS NULL;

DELETE rs
FROM [Reservations] AS rs
LEFT JOIN [Users] AS u ON u.[Id] = rs.[UserId]
LEFT JOIN [ParkingZones] AS pz ON pz.[Id] = rs.[ParkingZoneId]
LEFT JOIN [ParkingSpots] AS ps ON ps.[Id] = rs.[ParkingSpotId]
WHERE rs.[UserId] <= 0 OR u.[Id] IS NULL OR pz.[Id] IS NULL OR ps.[Id] IS NULL;

DELETE wt
FROM [WalletTransactions] AS wt
LEFT JOIN [Wallets] AS w ON w.[Id] = wt.[WalletId]
WHERE w.[Id] IS NULL;

DELETE pay
FROM [Payments] AS pay
LEFT JOIN [Users] AS u ON u.[Id] = pay.[UserId]
WHERE pay.[UserId] <= 0 OR u.[Id] IS NULL;

UPDATE pay
SET [ReservationId] = NULL
FROM [Payments] AS pay
LEFT JOIN [Reservations] AS rs ON rs.[Id] = pay.[ReservationId]
WHERE pay.[ReservationId] IS NOT NULL AND rs.[Id] IS NULL;

UPDATE pay
SET [WalletId] = NULL
FROM [Payments] AS pay
LEFT JOIN [Wallets] AS w ON w.[Id] = pay.[WalletId]
WHERE pay.[WalletId] IS NOT NULL AND w.[Id] IS NULL;

DELETE n
FROM [Notifications] AS n
LEFT JOIN [Users] AS u ON u.[Id] = n.[UserId]
WHERE n.[UserId] <= 0 OR u.[Id] IS NULL;

UPDATE n
SET [ReservationId] = NULL
FROM [Notifications] AS n
LEFT JOIN [Reservations] AS r ON r.[Id] = n.[ReservationId]
WHERE n.[ReservationId] IS NOT NULL AND r.[Id] IS NULL;

UPDATE n
SET [ParkingZoneId] = NULL
FROM [Notifications] AS n
LEFT JOIN [ParkingZones] AS pz ON pz.[Id] = n.[ParkingZoneId]
WHERE n.[ParkingZoneId] IS NOT NULL AND pz.[Id] IS NULL;
");

            migrationBuilder.CreateIndex(
                name: "IX_WalletTransactions_WalletId",
                table: "WalletTransactions",
                column: "WalletId");

            migrationBuilder.CreateIndex(
                name: "IX_Wallets_UserId",
                table: "Wallets",
                column: "UserId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Vehicles_UserId",
                table: "Vehicles",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_Reviews_ParkingZoneId",
                table: "Reviews",
                column: "ParkingZoneId");

            migrationBuilder.CreateIndex(
                name: "IX_Reviews_UserId",
                table: "Reviews",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_Reservations_ParkingSpotId",
                table: "Reservations",
                column: "ParkingSpotId");

            migrationBuilder.CreateIndex(
                name: "IX_Reservations_ParkingZoneId",
                table: "Reservations",
                column: "ParkingZoneId");

            migrationBuilder.CreateIndex(
                name: "IX_Reservations_UserId",
                table: "Reservations",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_Preferences_FavoriteParkingZoneId",
                table: "Preferences",
                column: "FavoriteParkingZoneId");

            migrationBuilder.CreateIndex(
                name: "IX_Preferences_PreferredCityId",
                table: "Preferences",
                column: "PreferredCityId");

            migrationBuilder.CreateIndex(
                name: "IX_Preferences_UserId",
                table: "Preferences",
                column: "UserId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Payments_ReservationId",
                table: "Payments",
                column: "ReservationId");

            migrationBuilder.CreateIndex(
                name: "IX_Payments_UserId",
                table: "Payments",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_Payments_WalletId",
                table: "Payments",
                column: "WalletId");

            migrationBuilder.CreateIndex(
                name: "IX_ParkingZones_CityId",
                table: "ParkingZones",
                column: "CityId");

            migrationBuilder.CreateIndex(
                name: "IX_Notifications_ParkingZoneId",
                table: "Notifications",
                column: "ParkingZoneId");

            migrationBuilder.CreateIndex(
                name: "IX_Notifications_ReservationId",
                table: "Notifications",
                column: "ReservationId");

            migrationBuilder.CreateIndex(
                name: "IX_Notifications_UserId",
                table: "Notifications",
                column: "UserId");

            migrationBuilder.AddForeignKey(
                name: "FK_Notifications_ParkingZones_ParkingZoneId",
                table: "Notifications",
                column: "ParkingZoneId",
                principalTable: "ParkingZones",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Notifications_Reservations_ReservationId",
                table: "Notifications",
                column: "ReservationId",
                principalTable: "Reservations",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Notifications_Users_UserId",
                table: "Notifications",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_ParkingSpots_ParkingZones_ParkingZoneId",
                table: "ParkingSpots",
                column: "ParkingZoneId",
                principalTable: "ParkingZones",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_ParkingZones_Cities_CityId",
                table: "ParkingZones",
                column: "CityId",
                principalTable: "Cities",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Payments_Reservations_ReservationId",
                table: "Payments",
                column: "ReservationId",
                principalTable: "Reservations",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Payments_Users_UserId",
                table: "Payments",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Payments_Wallets_WalletId",
                table: "Payments",
                column: "WalletId",
                principalTable: "Wallets",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Preferences_Cities_PreferredCityId",
                table: "Preferences",
                column: "PreferredCityId",
                principalTable: "Cities",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Preferences_ParkingZones_FavoriteParkingZoneId",
                table: "Preferences",
                column: "FavoriteParkingZoneId",
                principalTable: "ParkingZones",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Preferences_Users_UserId",
                table: "Preferences",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Reservations_ParkingSpots_ParkingSpotId",
                table: "Reservations",
                column: "ParkingSpotId",
                principalTable: "ParkingSpots",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Reservations_ParkingZones_ParkingZoneId",
                table: "Reservations",
                column: "ParkingZoneId",
                principalTable: "ParkingZones",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Reservations_Users_UserId",
                table: "Reservations",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Reviews_ParkingZones_ParkingZoneId",
                table: "Reviews",
                column: "ParkingZoneId",
                principalTable: "ParkingZones",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Reviews_Users_UserId",
                table: "Reviews",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Vehicles_Users_UserId",
                table: "Vehicles",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Wallets_Users_UserId",
                table: "Wallets",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_WalletTransactions_Wallets_WalletId",
                table: "WalletTransactions",
                column: "WalletId",
                principalTable: "Wallets",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Notifications_ParkingZones_ParkingZoneId",
                table: "Notifications");

            migrationBuilder.DropForeignKey(
                name: "FK_Notifications_Reservations_ReservationId",
                table: "Notifications");

            migrationBuilder.DropForeignKey(
                name: "FK_Notifications_Users_UserId",
                table: "Notifications");

            migrationBuilder.DropForeignKey(
                name: "FK_ParkingSpots_ParkingZones_ParkingZoneId",
                table: "ParkingSpots");

            migrationBuilder.DropForeignKey(
                name: "FK_ParkingZones_Cities_CityId",
                table: "ParkingZones");

            migrationBuilder.DropForeignKey(
                name: "FK_Payments_Reservations_ReservationId",
                table: "Payments");

            migrationBuilder.DropForeignKey(
                name: "FK_Payments_Users_UserId",
                table: "Payments");

            migrationBuilder.DropForeignKey(
                name: "FK_Payments_Wallets_WalletId",
                table: "Payments");

            migrationBuilder.DropForeignKey(
                name: "FK_Preferences_Cities_PreferredCityId",
                table: "Preferences");

            migrationBuilder.DropForeignKey(
                name: "FK_Preferences_ParkingZones_FavoriteParkingZoneId",
                table: "Preferences");

            migrationBuilder.DropForeignKey(
                name: "FK_Preferences_Users_UserId",
                table: "Preferences");

            migrationBuilder.DropForeignKey(
                name: "FK_Reservations_ParkingSpots_ParkingSpotId",
                table: "Reservations");

            migrationBuilder.DropForeignKey(
                name: "FK_Reservations_ParkingZones_ParkingZoneId",
                table: "Reservations");

            migrationBuilder.DropForeignKey(
                name: "FK_Reservations_Users_UserId",
                table: "Reservations");

            migrationBuilder.DropForeignKey(
                name: "FK_Reviews_ParkingZones_ParkingZoneId",
                table: "Reviews");

            migrationBuilder.DropForeignKey(
                name: "FK_Reviews_Users_UserId",
                table: "Reviews");

            migrationBuilder.DropForeignKey(
                name: "FK_Vehicles_Users_UserId",
                table: "Vehicles");

            migrationBuilder.DropForeignKey(
                name: "FK_Wallets_Users_UserId",
                table: "Wallets");

            migrationBuilder.DropForeignKey(
                name: "FK_WalletTransactions_Wallets_WalletId",
                table: "WalletTransactions");

            migrationBuilder.DropIndex(
                name: "IX_WalletTransactions_WalletId",
                table: "WalletTransactions");

            migrationBuilder.DropIndex(
                name: "IX_Wallets_UserId",
                table: "Wallets");

            migrationBuilder.DropIndex(
                name: "IX_Vehicles_UserId",
                table: "Vehicles");

            migrationBuilder.DropIndex(
                name: "IX_Reviews_ParkingZoneId",
                table: "Reviews");

            migrationBuilder.DropIndex(
                name: "IX_Reviews_UserId",
                table: "Reviews");

            migrationBuilder.DropIndex(
                name: "IX_Reservations_ParkingSpotId",
                table: "Reservations");

            migrationBuilder.DropIndex(
                name: "IX_Reservations_ParkingZoneId",
                table: "Reservations");

            migrationBuilder.DropIndex(
                name: "IX_Reservations_UserId",
                table: "Reservations");

            migrationBuilder.DropIndex(
                name: "IX_Preferences_FavoriteParkingZoneId",
                table: "Preferences");

            migrationBuilder.DropIndex(
                name: "IX_Preferences_PreferredCityId",
                table: "Preferences");

            migrationBuilder.DropIndex(
                name: "IX_Preferences_UserId",
                table: "Preferences");

            migrationBuilder.DropIndex(
                name: "IX_Payments_ReservationId",
                table: "Payments");

            migrationBuilder.DropIndex(
                name: "IX_Payments_UserId",
                table: "Payments");

            migrationBuilder.DropIndex(
                name: "IX_Payments_WalletId",
                table: "Payments");

            migrationBuilder.DropIndex(
                name: "IX_ParkingZones_CityId",
                table: "ParkingZones");

            migrationBuilder.DropIndex(
                name: "IX_Notifications_ParkingZoneId",
                table: "Notifications");

            migrationBuilder.DropIndex(
                name: "IX_Notifications_ReservationId",
                table: "Notifications");

            migrationBuilder.DropIndex(
                name: "IX_Notifications_UserId",
                table: "Notifications");

            migrationBuilder.AddForeignKey(
                name: "FK_ParkingSpots_ParkingZones_ParkingZoneId",
                table: "ParkingSpots",
                column: "ParkingZoneId",
                principalTable: "ParkingZones",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
