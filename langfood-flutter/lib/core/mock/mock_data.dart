import '../../data/models/category_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/product_option_model.dart';

class MockData {
  static List<CategoryModel> getCategories() {
    return [
      CategoryModel(id: -1, name: 'Tất cả', iconUrl: null),
      CategoryModel(id: 1, name: 'Cơm tấm', iconUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=120'),
      CategoryModel(id: 2, name: 'Bún / Phở', iconUrl: 'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=120'),
      CategoryModel(id: 3, name: 'Trà sữa', iconUrl: 'https://images.unsplash.com/photo-1558857563-b37cfb62a4d4?w=120'),
      CategoryModel(id: 4, name: 'Bánh mì', iconUrl: 'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=120'),
      CategoryModel(id: 5, name: 'Ăn vặt', iconUrl: 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=120'),
      CategoryModel(id: 6, name: 'Đồ uống', iconUrl: 'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?w=120'),
    ];
  }

  static List<ProductModel> getProducts() {
    return [
      ProductModel(
        id: 101,
        name: 'Cơm sườn bì chả đặc biệt',
        description: 'Cơm tấm thơm nóng dẻo, sườn nướng mật ong đậm vị thảo mộc, chả trứng hấp vàng óng và bì heo giòn dai cùng mỡ hành béo ngậy.',
        price: 35000,
        imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500',
        shopId: 1,
        shopName: 'Cơm Tấm Dì Năm - KTX B',
        categoryId: 1,
        categoryName: 'Cơm tấm',
        isAvailable: true,
        isShopOpen: true,
        optionGroups: [
          ProductOptionGroupModel(
            id: 1,
            name: 'Chọn thêm món kèm',
            isMultiple: true,
            options: [
              ProductOptionModel(id: 11, name: 'Trứng ốp la lòng đào', price: 6000),
              ProductOptionModel(id: 12, name: 'Chả trứng hấp thêm', price: 7000),
              ProductOptionModel(id: 13, name: 'Canh rong biển thịt bằm', price: 8000),
              ProductOptionModel(id: 14, name: 'Thêm chén cơm thêm', price: 4000),
            ],
          ),
          ProductOptionGroupModel(
            id: 2,
            name: 'Lượng nước mắm',
            isMultiple: false,
            options: [
              ProductOptionModel(id: 21, name: 'Nước mắm ngọt vừa (chuẩn)', price: 0, isSelected: true),
              ProductOptionModel(id: 22, name: 'Nước mắm cay nhiều', price: 0),
              ProductOptionModel(id: 23, name: 'Để riêng 2 bịch nước mắm', price: 0),
            ],
          ),
        ],
      ),
      ProductModel(
        id: 102,
        name: 'Bún bò Huế giò nạc chả cua',
        description: 'Nước dùng hầm xương đậm đà hương sả ruốc Huế đặc trưng, thịt bắp hoa thái lát, giò nạc mềm béo và chả cua thơm lừng.',
        price: 40000,
        imageUrl: 'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=500',
        shopId: 2,
        shopName: 'Bún Bò O Ánh - Cổng KTX',
        categoryId: 2,
        categoryName: 'Bún / Phở',
        isAvailable: true,
        isShopOpen: true,
        optionGroups: [
          ProductOptionGroupModel(
            id: 3,
            name: 'Loại bún',
            isMultiple: false,
            options: [
              ProductOptionModel(id: 31, name: 'Sợi bún to Huế chuẩn', price: 0, isSelected: true),
              ProductOptionModel(id: 32, name: 'Sợi bún nhỏ', price: 0),
            ],
          ),
          ProductOptionGroupModel(
            id: 4,
            name: 'Thêm Topping',
            isMultiple: true,
            options: [
              ProductOptionModel(id: 41, name: 'Khoanh giò nạc thêm', price: 12000),
              ProductOptionModel(id: 42, name: 'Chả cua viên to', price: 8000),
              ProductOptionModel(id: 43, name: 'Huyết luộc thêm', price: 5000),
            ],
          ),
        ],
      ),
      ProductModel(
        id: 103,
        name: 'Trà sữa nướng Trân Châu Hoàng Kim',
        description: 'Trà ô long nướng thơm khói hòa cùng sữa tươi béo ngọt dịu, trân châu hoàng kim nấu đường nâu dẻo dai ăn cực cuốn.',
        price: 26000,
        imageUrl: 'https://images.unsplash.com/photo-1558857563-b37cfb62a4d4?w=500',
        shopId: 3,
        shopName: 'Trà Sữa Làng ĐH (Tòa B4)',
        categoryId: 3,
        categoryName: 'Trà sữa',
        isAvailable: true,
        isShopOpen: true,
        optionGroups: [
          ProductOptionGroupModel(
            id: 5,
            name: 'Độ ngọt (Đường)',
            isMultiple: false,
            options: [
              ProductOptionModel(id: 51, name: '100% đường (Ngọt chuẩn)', price: 0),
              ProductOptionModel(id: 52, name: '70% đường (Vừa phải)', price: 0, isSelected: true),
              ProductOptionModel(id: 53, name: '50% đường (Ít ngọt)', price: 0),
              ProductOptionModel(id: 54, name: '30% đường (Thanh mát)', price: 0),
            ],
          ),
          ProductOptionGroupModel(
            id: 6,
            name: 'Mức đá',
            isMultiple: false,
            options: [
              ProductOptionModel(id: 61, name: '100% đá (Chuẩn mát)', price: 0, isSelected: true),
              ProductOptionModel(id: 62, name: '70% đá', price: 0),
              ProductOptionModel(id: 63, name: 'Đá riêng ly', price: 0),
            ],
          ),
          ProductOptionGroupModel(
            id: 7,
            name: 'Thêm Topping siêu ngon',
            isMultiple: true,
            options: [
              ProductOptionModel(id: 71, name: 'Pudding trứng béo ngậy', price: 6000),
              ProductOptionModel(id: 72, name: 'Thạch củ năng giòn', price: 5000),
              ProductOptionModel(id: 73, name: 'Kem cheese mặn dẻo', price: 8000),
            ],
          ),
        ],
      ),
      ProductModel(
        id: 104,
        name: 'Bánh mì thịt nướng pate bơ tỏi',
        description: 'Bánh mì giòn rụm nướng nóng hổi, nhân thịt nướng xiên mè, pate béo gan heo tươi tự làm, dưa leo chua giòn và ớt cay.',
        price: 22000,
        imageUrl: 'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=500',
        shopId: 4,
        shopName: 'Bánh Mì Bác Ba - Trạm Xe Buýt B',
        categoryId: 4,
        categoryName: 'Bánh mì',
        isAvailable: true,
        isShopOpen: true,
        optionGroups: [
          ProductOptionGroupModel(
            id: 8,
            name: 'Gia vị & Ớt',
            isMultiple: false,
            options: [
              ProductOptionModel(id: 81, name: 'Cay vừa có tương ớt + ớt lát', price: 0, isSelected: true),
              ProductOptionModel(id: 82, name: 'Không cay (không ớt, không tiêu)', price: 0),
              ProductOptionModel(id: 83, name: 'Siêu cay nhiều ớt', price: 0),
            ],
          ),
          ProductOptionGroupModel(
            id: 9,
            name: 'Thêm nhân',
            isMultiple: true,
            options: [
              ProductOptionModel(id: 91, name: 'Thêm xá xíu rim', price: 6000),
              ProductOptionModel(id: 92, name: 'Thêm phô mai con bò cười', price: 5000),
            ],
          ),
        ],
      ),
      ProductModel(
        id: 105,
        name: 'Cơm gà xối mỡ đùi góc tư giòn rụm',
        description: 'Đùi gà chiên da giòn rụm thịt mềm ngọt, cơm chiên cà chua hạt ngọc đỏ vàng tơi xốp kèm nước sốt tương gừng đặc chế.',
        price: 38000,
        imageUrl: 'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=500',
        shopId: 1,
        shopName: 'Cơm Tấm Dì Năm - KTX B',
        categoryId: 1,
        categoryName: 'Cơm tấm',
        isAvailable: true,
        isShopOpen: true,
      ),
      ProductModel(
        id: 106,
        name: 'Mì cay hải sản Kim Chi cấp độ 2',
        description: 'Tô mì cay Hàn Quốc nấu sôi sùng sục gồm tôm tươi, mực giòn, xúc xích Đức, bò mỹ cuộn nấm kim châm và rau củ thơm ngon.',
        price: 45000,
        imageUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=500',
        shopId: 5,
        shopName: 'Mì Cay Seoul KTX (Tòa BA4)',
        categoryId: 2,
        categoryName: 'Bún / Phở',
        isAvailable: true,
        isShopOpen: true,
      ),
    ];
  }
}
