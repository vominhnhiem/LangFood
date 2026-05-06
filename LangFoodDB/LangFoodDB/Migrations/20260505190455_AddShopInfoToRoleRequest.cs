using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LangFoodDB.Migrations
{
    /// <inheritdoc />
    public partial class AddShopInfoToRoleRequest : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "ShopAddress",
                table: "RoleRequests",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ShopName",
                table: "RoleRequests",
                type: "nvarchar(200)",
                maxLength: 200,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ShopAddress",
                table: "RoleRequests");

            migrationBuilder.DropColumn(
                name: "ShopName",
                table: "RoleRequests");
        }
    }
}
