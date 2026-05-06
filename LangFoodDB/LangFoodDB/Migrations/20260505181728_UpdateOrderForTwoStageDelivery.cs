using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LangFoodDB.Migrations
{
    /// <inheritdoc />
    public partial class UpdateOrderForTwoStageDelivery : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "DeliveryStage",
                table: "Orders",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "ExternalShipperId",
                table: "Orders",
                type: "int",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "DeliveryStage",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "ExternalShipperId",
                table: "Orders");
        }
    }
}
