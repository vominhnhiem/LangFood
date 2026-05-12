using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LangFoodBackend.Migrations
{
    /// <inheritdoc />
    public partial class AddBuildingIdToOrder : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "BuildingId",
                table: "Orders",
                type: "int",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Orders_BuildingId",
                table: "Orders",
                column: "BuildingId");

            migrationBuilder.AddForeignKey(
                name: "FK_Orders_Buildings_BuildingId",
                table: "Orders",
                column: "BuildingId",
                principalTable: "Buildings",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Orders_Buildings_BuildingId",
                table: "Orders");

            migrationBuilder.DropIndex(
                name: "IX_Orders_BuildingId",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "BuildingId",
                table: "Orders");
        }
    }
}
