using LangFood.Shared.Models;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

namespace LangFood.Shared.Migrations
{
    [DbContext(typeof(LangFoodDbContext))]
    [Migration("20261104090000_AddShopPickupCoordinates")]
    public class AddShopPickupCoordinates : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<double>("PickupLatitude", "Shops", type: "float", nullable: true);
            migrationBuilder.AddColumn<double>("PickupLongitude", "Shops", type: "float", nullable: true);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn("PickupLatitude", "Shops");
            migrationBuilder.DropColumn("PickupLongitude", "Shops");
        }
    }
}
