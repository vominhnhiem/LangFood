using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LangFoodBackend.Migrations
{
    /// <inheritdoc />
    public partial class finalbase : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "WalletBalance",
                table: "Shops");

            migrationBuilder.DropColumn(
                name: "WalletBalance",
                table: "Shippers");

            migrationBuilder.AddColumn<int>(
                name: "OrderId1",
                table: "Transactions",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "WalletId1",
                table: "Transactions",
                type: "int",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Transactions_OrderId1",
                table: "Transactions",
                column: "OrderId1");

            migrationBuilder.CreateIndex(
                name: "IX_Transactions_WalletId1",
                table: "Transactions",
                column: "WalletId1");

            migrationBuilder.AddForeignKey(
                name: "FK_Transactions_Orders_OrderId1",
                table: "Transactions",
                column: "OrderId1",
                principalTable: "Orders",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_Transactions_Wallets_WalletId1",
                table: "Transactions",
                column: "WalletId1",
                principalTable: "Wallets",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Transactions_Orders_OrderId1",
                table: "Transactions");

            migrationBuilder.DropForeignKey(
                name: "FK_Transactions_Wallets_WalletId1",
                table: "Transactions");

            migrationBuilder.DropIndex(
                name: "IX_Transactions_OrderId1",
                table: "Transactions");

            migrationBuilder.DropIndex(
                name: "IX_Transactions_WalletId1",
                table: "Transactions");

            migrationBuilder.DropColumn(
                name: "OrderId1",
                table: "Transactions");

            migrationBuilder.DropColumn(
                name: "WalletId1",
                table: "Transactions");

            migrationBuilder.AddColumn<decimal>(
                name: "WalletBalance",
                table: "Shops",
                type: "decimal(18,2)",
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<decimal>(
                name: "WalletBalance",
                table: "Shippers",
                type: "decimal(18,2)",
                nullable: false,
                defaultValue: 0m);
        }
    }
}
