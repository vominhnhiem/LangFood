using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LangFoodBackend.Migrations
{
    /// <inheritdoc />
    public partial class AddAdminPermissionFlags : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "CanManageFinance",
                table: "Users",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "CanManageOrders",
                table: "Users",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "CanManageShops",
                table: "Users",
                type: "bit",
                nullable: false,
                defaultValue: false);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "CanManageFinance",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "CanManageOrders",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "CanManageShops",
                table: "Users");
        }
    }
}
