import '../../data/models/category_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/product_option_model.dart';

/// Dữ liệu mẫu đồng bộ 100% với cơ sở dữ liệu thật trong seed_data.sql
/// Dùng làm fallback ngoại tuyến an toàn khi thiết bị mất kết nối mạng.
class MockData {
  static List<CategoryModel> getCategories() {
    return [
      CategoryModel(id: -1, name: 'Tất cả', iconUrl: null),
      CategoryModel(
        id: 1,
        name: 'Cơm tấm & Cơm phần',
        iconUrl:
            'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400&auto=format&fit=crop&q=80',
      ),
      CategoryModel(
        id: 2,
        name: 'Bún, Phở & Mì nước',
        iconUrl:
            'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=400&auto=format&fit=crop&q=80',
      ),
      CategoryModel(
        id: 3,
        name: 'Trà sữa & Trà trái cây',
        iconUrl:
            'https://images.unsplash.com/photo-1558857563-b37cfb62a4d4?w=400&auto=format&fit=crop&q=80',
      ),
      CategoryModel(
        id: 4,
        name: 'Bánh mì & Fast Food',
        iconUrl:
            'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=400&auto=format&fit=crop&q=80',
      ),
      CategoryModel(
        id: 5,
        name: 'Ăn vặt KTX',
        iconUrl:
            'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=400&auto=format&fit=crop&q=80',
      ),
      CategoryModel(
        id: 6,
        name: 'Cà phê & Đồ uống',
        iconUrl:
            'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=400&auto=format&fit=crop&q=80',
      ),
    ];
  }

  static List<ProductModel> getProducts() {
    return [
      ProductModel(
        id: 1,
        name: 'Cơm sườn bì chả đặc biệt',
        description:
            'Cơm tấm thơm nóng dẻo, sườn nướng mật ong đậm vị thảo mộc, chả trứng hấp vàng óng và bì heo giòn dai cùng mỡ hành béo ngậy.',
        price: 35000,
        imageUrl:
            'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600&auto=format&fit=crop&q=80',
        shopId: 1,
        shopName: 'Cơm Tấm Dì Năm - KTX B',
        categoryId: 1,
        categoryName: 'Cơm tấm & Cơm phần',
        isAvailable: true,
        isShopOpen: true,
        optionGroups: [
          ProductOptionGroupModel(
            id: 1,
            name: 'Chọn thêm món kèm',
            isMultiple: true,
            options: [
              ProductOptionModel(
                id: 1,
                name: 'Trứng ốp la lòng đào',
                price: 6000,
              ),
              ProductOptionModel(
                id: 2,
                name: 'Chả trứng hấp thêm miếng to',
                price: 7000,
              ),
              ProductOptionModel(
                id: 3,
                name: 'Canh rong biển thịt bằm',
                price: 8000,
              ),
              ProductOptionModel(
                id: 4,
                name: 'Thêm một chén cơm thêm',
                price: 4000,
              ),
            ],
          ),
          ProductOptionGroupModel(
            id: 2,
            name: 'Lượng nước mắm',
            isMultiple: false,
            options: [
              ProductOptionModel(
                id: 5,
                name: 'Nước mắm ngọt vừa (chuẩn vị)',
                price: 0,
                isSelected: true,
              ),
              ProductOptionModel(
                id: 6,
                name: 'Nước mắm cay nhiều ớt tươi',
                price: 0,
              ),
              ProductOptionModel(
                id: 7,
                name: 'Để riêng bịch nước mắm',
                price: 0,
              ),
            ],
          ),
        ],
      ),
      ProductModel(
        id: 2,
        name: 'Cơm đùi gà góc tư xối mỡ',
        description:
            'Đùi gà góc tư chiên giòn rụm bên ngoài mọng nước bên trong, ăn kèm dưa leo, cà chua và tương ớt tỏi cay thơm.',
        price: 38000,
        imageUrl:
            'https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?w=600&auto=format&fit=crop&q=80',
        shopId: 1,
        shopName: 'Cơm Tấm Dì Năm - KTX B',
        categoryId: 1,
        categoryName: 'Cơm tấm & Cơm phần',
        isAvailable: true,
        isShopOpen: true,
      ),
      ProductModel(
        id: 4,
        name: 'Bún bò Huế giò nạc chả cua',
        description:
            'Nước dùng hầm xương đậm đà hương sả ruốc Huế đặc trưng, thịt bắp hoa thái lát, giò nạc mềm béo và chả cua thơm lừng.',
        price: 40000,
        imageUrl:
            'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=600&auto=format&fit=crop&q=80',
        shopId: 2,
        shopName: 'Bún Bò O Ánh - Cổng KTX Khu B',
        categoryId: 2,
        categoryName: 'Bún, Phở & Mì nước',
        isAvailable: true,
        isShopOpen: true,
        optionGroups: [
          ProductOptionGroupModel(
            id: 3,
            name: 'Loại bún',
            isMultiple: false,
            options: [
              ProductOptionModel(
                id: 8,
                name: 'Sợi bún to Huế chuẩn',
                price: 0,
                isSelected: true,
              ),
              ProductOptionModel(
                id: 9,
                name: 'Sợi bún nhỏ',
                price: 0,
              ),
            ],
          ),
          ProductOptionGroupModel(
            id: 4,
            name: 'Thêm Topping',
            isMultiple: true,
            options: [
              ProductOptionModel(
                id: 10,
                name: 'Khoanh giò nạc mềm thêm',
                price: 12000,
              ),
              ProductOptionModel(
                id: 11,
                name: 'Chả cua viên to thơm',
                price: 8000,
              ),
              ProductOptionModel(
                id: 12,
                name: 'Huyết luộc thêm',
                price: 5000,
              ),
              ProductOptionModel(
                id: 13,
                name: 'Thịt bắp bò hoa thêm',
                price: 15000,
              ),
            ],
          ),
        ],
      ),
      ProductModel(
        id: 7,
        name: 'Trà sữa nướng Trân Châu Hoàng Kim',
        description:
            'Trà ô long nướng thơm khói hòa cùng sữa tươi béo ngọt dịu, trân châu hoàng kim nấu đường nâu dẻo dai ăn cực cuốn.',
        price: 26000,
        imageUrl:
            'https://images.unsplash.com/photo-1558857563-b37cfb62a4d4?w=600&auto=format&fit=crop&q=80',
        shopId: 3,
        shopName: 'Trà Sữa Làng ĐH - Tòa B4',
        categoryId: 3,
        categoryName: 'Trà sữa & Trà trái cây',
        isAvailable: true,
        isShopOpen: true,
        optionGroups: [
          ProductOptionGroupModel(
            id: 5,
            name: 'Chọn Size ly',
            isMultiple: false,
            options: [
              ProductOptionModel(
                id: 14,
                name: 'Size M vừa vặn (500ml)',
                price: 0,
                isSelected: true,
              ),
              ProductOptionModel(
                id: 15,
                name: 'Size L lớn đã khát (700ml)',
                price: 6000,
              ),
            ],
          ),
          ProductOptionGroupModel(
            id: 6,
            name: 'Độ ngọt (Đường)',
            isMultiple: false,
            options: [
              ProductOptionModel(
                id: 16,
                name: '100% đường (Ngọt chuẩn quán)',
                price: 0,
              ),
              ProductOptionModel(
                id: 17,
                name: '70% đường (Vừa phải dễ uống)',
                price: 0,
                isSelected: true,
              ),
              ProductOptionModel(
                id: 18,
                name: '50% đường (Ít ngọt healthy)',
                price: 0,
              ),
              ProductOptionModel(
                id: 19,
                name: '30% đường (Thanh mát)',
                price: 0,
              ),
            ],
          ),
          ProductOptionGroupModel(
            id: 7,
            name: 'Mức đá',
            isMultiple: false,
            options: [
              ProductOptionModel(
                id: 20,
                name: '100% đá (Mát lạnh sảng khoái)',
                price: 0,
                isSelected: true,
              ),
              ProductOptionModel(
                id: 21,
                name: '50% đá (Ít đá)',
                price: 0,
              ),
              ProductOptionModel(
                id: 22,
                name: 'Đá riêng ra ly',
                price: 0,
              ),
            ],
          ),
          ProductOptionGroupModel(
            id: 8,
            name: 'Thêm Topping siêu ngon',
            isMultiple: true,
            options: [
              ProductOptionModel(
                id: 23,
                name: 'Pudding trứng béo ngậy',
                price: 6000,
              ),
              ProductOptionModel(
                id: 24,
                name: 'Thạch củ năng giòn sần sật',
                price: 5000,
              ),
              ProductOptionModel(
                id: 25,
                name: 'Kem cheese mặn dẻo quánh',
                price: 8000,
              ),
              ProductOptionModel(
                id: 26,
                name: 'Trân châu hoàng kim thêm',
                price: 5000,
              ),
            ],
          ),
        ],
      ),
      ProductModel(
        id: 9,
        name: 'Bánh mì thịt nướng pate bơ tỏi',
        description:
            'Bánh mì giòn rụm nướng nóng hổi, nhân thịt nướng xiên mè, pate béo gan heo tươi tự làm, dưa leo chua giòn và ớt cay.',
        price: 22000,
        imageUrl:
            'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=600&auto=format&fit=crop&q=80',
        shopId: 4,
        shopName: 'Bánh Mì Bác Ba - Trạm Xe Buýt KTX',
        categoryId: 4,
        categoryName: 'Bánh mì & Fast Food',
        isAvailable: true,
        isShopOpen: true,
        optionGroups: [
          ProductOptionGroupModel(
            id: 9,
            name: 'Gia vị & Ớt',
            isMultiple: false,
            options: [
              ProductOptionModel(
                id: 27,
                name: 'Cay vừa (Tương ớt + ít ớt lát)',
                price: 0,
                isSelected: true,
              ),
              ProductOptionModel(
                id: 28,
                name: 'Không cay (Không cho ớt)',
                price: 0,
              ),
              ProductOptionModel(
                id: 29,
                name: 'Rất cay (Nhiều ớt hiểm)',
                price: 0,
              ),
            ],
          ),
          ProductOptionGroupModel(
            id: 10,
            name: 'Thêm nhân bánh',
            isMultiple: true,
            options: [
              ProductOptionModel(
                id: 30,
                name: 'Thịt nướng xiên thêm',
                price: 8000,
              ),
              ProductOptionModel(
                id: 31,
                name: 'Trứng ốp la thêm',
                price: 6000,
              ),
              ProductOptionModel(
                id: 32,
                name: 'Chả lụa thêm',
                price: 6000,
              ),
            ],
          ),
        ],
      ),
      ProductModel(
        id: 11,
        name: 'Cà phê muối xứ Huế đậm đà',
        description:
            'Cà phê Robusta Đắk Lắk pha phin nguyên chất kết hợp lớp kem sữa muối mặn ngọt béo bùi chuẩn vị xứ Huế.',
        price: 20000,
        imageUrl:
            'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=600&auto=format&fit=crop&q=80',
        shopId: 5,
        shopName: 'Cà Phê Sinh Viên 1995 - Sảnh A1',
        categoryId: 6,
        categoryName: 'Cà phê & Đồ uống',
        isAvailable: true,
        isShopOpen: true,
        optionGroups: [
          ProductOptionGroupModel(
            id: 11,
            name: 'Lượng ngọt & đá',
            isMultiple: false,
            options: [
              ProductOptionModel(
                id: 33,
                name: 'Ngọt chuẩn đậm đà (Ít đá)',
                price: 0,
                isSelected: true,
              ),
              ProductOptionModel(
                id: 34,
                name: 'Ít ngọt đậm vị cà phê',
                price: 0,
              ),
              ProductOptionModel(
                id: 35,
                name: 'Nhiều đá mát lạnh',
                price: 0,
              ),
            ],
          ),
          ProductOptionGroupModel(
            id: 12,
            name: 'Thêm kem muối béo',
            isMultiple: false,
            options: [
              ProductOptionModel(
                id: 36,
                name: 'Gấp đôi kem muối béo',
                price: 5000,
              ),
            ],
          ),
        ],
      ),
    ];
  }
}
