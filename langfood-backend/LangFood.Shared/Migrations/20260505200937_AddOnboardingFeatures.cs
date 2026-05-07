using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LangFoodBackend.Migrations
{
    /// <inheritdoc />
    public partial class AddOnboardingFeatures : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "AccountType",
                table: "Users",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<string>(
                name: "CccdNumber",
                table: "Users",
                type: "nvarchar(20)",
                maxLength: 20,
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsApproved",
                table: "Users",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<int>(
                name: "DeliveryStage",
                table: "Orders",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<string>(
                name: "ExternalShipperId",
                table: "Orders",
                type: "nvarchar(450)",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "RoleRequests",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    UserId = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    RequestType = table.Column<int>(type: "int", nullable: false),
                    ImageProof = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    ShopName = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: true),
                    ShopAddress = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    Status = table.Column<int>(type: "int", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_RoleRequests", x => x.Id);
                    table.ForeignKey(
                        name: "FK_RoleRequests_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateIndex(
                name: "IX_Orders_ExternalShipperId",
                table: "Orders",
                column: "ExternalShipperId");

            migrationBuilder.CreateIndex(
                name: "IX_RoleRequests_UserId",
                table: "RoleRequests",
                column: "UserId");

            migrationBuilder.AddForeignKey(
                name: "FK_Orders_Users_ExternalShipperId",
                table: "Orders",
                column: "ExternalShipperId",
                principalTable: "Users",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Orders_Users_ExternalShipperId",
                table: "Orders");

            migrationBuilder.DropTable(
                name: "RoleRequests");

            migrationBuilder.DropIndex(
                name: "IX_Orders_ExternalShipperId",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "AccountType",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "CccdNumber",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "IsApproved",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "DeliveryStage",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "ExternalShipperId",
                table: "Orders");
        }
    }
}
