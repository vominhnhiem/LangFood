using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LangFoodBackend.Migrations
{
    /// <inheritdoc />
    public partial class FinalFixOrderShipper : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Orders_Shippers_Leg1ShipperId",
                table: "Orders");

            migrationBuilder.DropForeignKey(
                name: "FK_Orders_Shippers_Leg2ShipperId",
                table: "Orders");

            migrationBuilder.DropIndex(
                name: "IX_Orders_Leg1ShipperId",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "DeliveryStage",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "Leg1ShipperId",
                table: "Orders");

            migrationBuilder.RenameColumn(
                name: "Leg2ShipperId",
                table: "Orders",
                newName: "ShipperId");

            migrationBuilder.RenameIndex(
                name: "IX_Orders_Leg2ShipperId",
                table: "Orders",
                newName: "IX_Orders_ShipperId");

            migrationBuilder.AddColumn<decimal>(
                name: "WalletBalance",
                table: "Shops",
                type: "decimal(18,2)",
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<string>(
                name: "DeliveryRoom",
                table: "Orders",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddForeignKey(
                name: "FK_Orders_Shippers_ShipperId",
                table: "Orders",
                column: "ShipperId",
                principalTable: "Shippers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Orders_Shippers_ShipperId",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "WalletBalance",
                table: "Shops");

            migrationBuilder.DropColumn(
                name: "DeliveryRoom",
                table: "Orders");

            migrationBuilder.RenameColumn(
                name: "ShipperId",
                table: "Orders",
                newName: "Leg2ShipperId");

            migrationBuilder.RenameIndex(
                name: "IX_Orders_ShipperId",
                table: "Orders",
                newName: "IX_Orders_Leg2ShipperId");

            migrationBuilder.AddColumn<int>(
                name: "DeliveryStage",
                table: "Orders",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "Leg1ShipperId",
                table: "Orders",
                type: "int",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Orders_Leg1ShipperId",
                table: "Orders",
                column: "Leg1ShipperId");

            migrationBuilder.AddForeignKey(
                name: "FK_Orders_Shippers_Leg1ShipperId",
                table: "Orders",
                column: "Leg1ShipperId",
                principalTable: "Shippers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Orders_Shippers_Leg2ShipperId",
                table: "Orders",
                column: "Leg2ShipperId",
                principalTable: "Shippers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }
    }
}
