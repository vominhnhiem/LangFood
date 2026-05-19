using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LangFoodBackend.Migrations
{
    /// <inheritdoc />
    public partial class themorderSDT : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "DeliveryPhone",
                table: "Orders",
                type: "nvarchar(20)",
                maxLength: 20,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "DeliveryPhone",
                table: "Orders");
        }
    }
}
