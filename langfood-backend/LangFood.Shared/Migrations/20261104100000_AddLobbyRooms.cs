using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LangFood.Shared.Migrations
{
    /// <inheritdoc />
    public partial class AddLobbyRooms : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Some deployed databases already have this legacy column outside EF history.
            migrationBuilder.Sql("""
                IF COL_LENGTH(N'dbo.Orders', N'CommissionFee') IS NULL
                    ALTER TABLE [dbo].[Orders] ADD [CommissionFee] decimal(18,2) NOT NULL
                        CONSTRAINT [DF_Orders_CommissionFee] DEFAULT 2000;
                """);

            migrationBuilder.CreateTable(
                name: "LobbyRooms",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    BuildingId = table.Column<int>(type: "int", nullable: false),
                    ShopId = table.Column<int>(type: "int", nullable: false),
                    HostId = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    ClosesAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Address = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Latitude = table.Column<double>(type: "float", nullable: false),
                    Longitude = table.Column<double>(type: "float", nullable: false),
                    PortionsJson = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    OrderId = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_LobbyRooms", x => x.Id);
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "LobbyRooms");

        }
    }
}
