import '../../data/models/category_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/product_option_model.dart';

class MockData {
  static List<CategoryModel> getCategories() {
    return [
      CategoryModel(id: -1, name: 'Tất cả', iconUrl: null),
      CategoryModel(id: 1, name: 'Cơm trưa (Hot)', iconUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=120'),
      CategoryModel(id: 2, name: 'Trà sữa & Cafe', iconUrl: 'https://images.unsplash.com/photo-1558857563-b37cfb62a4d4?w=120'),
      CategoryModel(id: 3, name: 'Mì & Bún', iconUrl: 'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=120'),
      CategoryModel(id: 4, name: 'Ăn vặt KTX', iconUrl: 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=120'),
      CategoryModel(id: 5, name: 'Bánh mì', iconUrl: 'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=120'),
      CategoryModel(id: 6, name: 'Đồ uống', iconUrl: 'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?w=120'),
    ];
  }

  static List<ProductModel> getProducts() {
    return [
      // 1. Cơm Gà Xối Mỡ Da Giòn Bà Tám
      ProductModel(
        id: 201,
        name: 'Cơm gà xối mỡ đùi góc tư giòn rụm',
        description: 'Đùi gà góc tư chiên xối mỡ vàng ươm giòn rụm, cơm chiên hạt ngọc đỏ sốt cà tơi xốp kèm nước tương tỏi ớt gừng gia truyền.',
        price: 35000,
        imageUrl: 'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=500',
        shopId: 10,
        shopName: 'Cơm Gà Xối Mỡ Da Giòn Bà Tám',
        categoryId: 1,
        categoryName: 'Cơm trưa (Hot)',
        isAvailable: true,
        isShopOpen: true,
        optionGroups: [
          ProductOptionGroupModel(
            id: 1,
            name: 'Món gọi thêm kèm cơm gà',
            isMultiple: true,
            options: [
              ProductOptionModel(id: 11, name: 'Trứng ốp la lòng đào', price: 6000),
              ProductOptionModel(id: 12, name: 'Canh rong biển thịt bằm', price: 8000),
              ProductOptionModel(id: 13, name: 'Cơm chiên thêm 1 chén', price: 5000),
              ProductOptionModel(id: 14, name: 'Tặng trà tắc giải ngấy (0đ)', price: 0, isSelected: true),
            ],
          ),
          ProductOptionGroupModel(
            id: 2,
            name: 'Gia vị nước chấm',
            isMultiple: false,
            options: [
              ProductOptionModel(id: 21, name: 'Nước tương gừng tỏi ớt (chuẩn)', price: 0, isSelected: true),
              ProductOptionModel(id: 22, name: 'Nước mắm ngọt cay nhiều', price: 0),
              ProductOptionModel(id: 23, name: 'Để riêng 2 bịch tương ớt xí muội', price: 0),
            ],
          ),
        ],
      ),
      ProductModel(
        id: 202,
        name: 'Cơm gà xối mỡ cánh gà sốt chua ngọt',
        description: '2 cánh gà chiên giòn sốt mắm tỏi mật ong thơm phức, ăn kèm dưa leo, cà chua và đồ chua giòn ngọt.',
        price: 32000,
        imageUrl: 'https://images.unsplash.com/photo-1562967914-608f82629710?w=500',
        shopId: 10,
        shopName: 'Cơm Gà Xối Mỡ Da Giòn Bà Tám',
        categoryId: 1,
        categoryName: 'Cơm trưa (Hot)',
        isAvailable: true,
        isShopOpen: true,
        optionGroups: [
          ProductOptionGroupModel(
            id: 3,
            name: 'Chọn thêm topping',
            isMultiple: true,
            options: [
              ProductOptionModel(id: 31, name: 'Thêm trứng ốp la', price: 6000),
              ProductOptionModel(id: 32, name: 'Canh súp thịt bằm', price: 7000),
            ],
          ),
        ],
      ),

      // 2. Trà Sữa Nướng Vân Nam KTX
      ProductModel(
        id: 204,
        name: 'Trà sữa nướng trân châu hoàng kim',
        description: 'Trà ô long nướng thơm hương khói nhẹ nhàng hòa cùng sữa tươi Đà Lạt béo ngậy, trân châu hoàng kim dai dẻo chuẩn vị.',
        price: 26000,
        imageUrl: 'https://images.unsplash.com/photo-1558857563-b37cfb62a4d4?w=500',
        shopId: 11,
        shopName: 'Trà Sữa Nướng Vân Nam KTX',
        categoryId: 2,
        categoryName: 'Trà sữa & Cafe',
        isAvailable: true,
        isShopOpen: true,
        optionGroups: [
          ProductOptionGroupModel(
            id: 4,
            name: 'Mức đường',
            isMultiple: false,
            options: [
              ProductOptionModel(id: 41, name: '70% đường (Vừa ngọt - Chuẩn quán)', price: 0, isSelected: true),
              ProductOptionModel(id: 42, name: '100% đường (Ngọt đậm)', price: 0),
              ProductOptionModel(id: 43, name: '50% đường (Ít ngọt thanh mát)', price: 0),
              ProductOptionModel(id: 44, name: '30% đường (Ít ngọt)', price: 0),
            ],
          ),
          ProductOptionGroupModel(
            id: 5,
            name: 'Mức đá',
            isMultiple: false,
            options: [
              ProductOptionModel(id: 51, name: '100% đá (Mát lạnh)', price: 0, isSelected: true),
              ProductOptionModel(id: 52, name: '70% đá', price: 0),
              ProductOptionModel(id: 53, name: 'Đá riêng mang về KTX', price: 0),
            ],
          ),
          ProductOptionGroupModel(
            id: 6,
            name: 'Khuyến mãi độc quyền & Topping',
            isMultiple: true,
            options: [
              ProductOptionModel(id: 61, name: 'Mua 1 tặng 1 thạch củ năng (0đ)', price: 0, isSelected: true),
              ProductOptionModel(id: 62, name: 'Pudding trứng phô mai mềm mịn', price: 6000),
              ProductOptionModel(id: 63, name: 'Kem cheese nướng dẻo ngậy', price: 8000),
            ],
          ),
        ],
      ),
      ProductModel(
        id: 205,
        name: 'Trà lài đác thơm hạt chia giải nhiệt',
        description: 'Trà hoa lài ủ lạnh thơm nức, hạt đác rim thơm dẻo quánh cùng hạt chia thanh mát, xua tan cái nóng trưa Làng ĐH.',
        price: 22000,
        imageUrl: 'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?w=500',
        shopId: 11,
        shopName: 'Trà Sữa Nướng Vân Nam KTX',
        categoryId: 2,
        categoryName: 'Trà sữa & Cafe',
        isAvailable: true,
        isShopOpen: true,
      ),

      // 3. Bún Đậu Phố Làng ĐH
      ProductModel(
        id: 207,
        name: 'Mẹt bún đậu thập cẩm chả cốm nem rán',
        description: 'Mẹt bún lá tươi ngon, đậu hũ chiên ngoài giòn trong mềm, chả cốm làng Vòng béo dẻo, nem chua rán nóng hổi và dồi sụn nướng thơm ngất ngây.',
        price: 38000,
        imageUrl: 'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=500',
        shopId: 12,
        shopName: 'Bún Đậu Phố Làng ĐH',
        categoryId: 3,
        categoryName: 'Mì & Bún',
        isAvailable: true,
        isShopOpen: true,
        optionGroups: [
          ProductOptionGroupModel(
            id: 7,
            name: 'Loại nước chấm chuẩn Phố Cổ',
            isMultiple: false,
            options: [
              ProductOptionModel(id: 71, name: 'Mắm tôm Thanh Hóa đánh sủi bọt (chuẩn)', price: 0, isSelected: true),
              ProductOptionModel(id: 72, name: 'Nước mắm tỏi ớt ngọt thanh', price: 0),
            ],
          ),
          ProductOptionGroupModel(
            id: 8,
            name: 'Topping gọi thêm giòn tan',
            isMultiple: true,
            options: [
              ProductOptionModel(id: 81, name: 'Chả cốm chiên nóng thêm', price: 8000),
              ProductOptionModel(id: 82, name: 'Nem chua rán Phố Cổ', price: 9000),
              ProductOptionModel(id: 83, name: 'Tặng kèm kẹo gum & trà tắc (0đ)', price: 0, isSelected: true),
            ],
          ),
        ],
      ),

      // 4. Bánh Tráng Cuộn Cô Ba
      ProductModel(
        id: 209,
        name: 'Bánh tráng cuộn bơ trứng cút sốt me',
        description: 'Bánh tráng dẻo Tây Ninh cuộn đầy ắp trứng cút lòng đào, sốt bơ béo ngậy, sốt me chua cay, khô bò vụn, hành phi giòn tan và đậu phộng.',
        price: 18000,
        imageUrl: 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=500',
        shopId: 13,
        shopName: 'Bánh Tráng Cuộn Cô Ba',
        categoryId: 4,
        categoryName: 'Ăn vặt KTX',
        isAvailable: true,
        isShopOpen: true,
        optionGroups: [
          ProductOptionGroupModel(
            id: 9,
            name: 'Mức cay sa tế',
            isMultiple: false,
            options: [
              ProductOptionModel(id: 91, name: 'Cay vừa vừa (chuẩn vị)', price: 0, isSelected: true),
              ProductOptionModel(id: 92, name: 'Siêu cay nhiều ớt hiểm', price: 0),
              ProductOptionModel(id: 93, name: 'Không cay (cho bạn nào không ăn ớt)', price: 0),
            ],
          ),
          ProductOptionGroupModel(
            id: 10,
            name: 'Topping thêm',
            isMultiple: true,
            options: [
              ProductOptionModel(id: 101, name: 'Thêm 3 quả trứng cút lòng đào', price: 5000),
              ProductOptionModel(id: 102, name: 'Thêm sốt bơ trứng muối béo', price: 4000),
            ],
          ),
        ],
      ),
      ProductModel(
        id: 210,
        name: 'Trứng cút nướng chén sốt phô mai kéo sợi',
        description: 'Chén đất nướng trên than hoa nóng hổi gồm 4 quả trứng cút, phô mai mozzarella kéo sợi, tép rim hành phi thơm phức.',
        price: 15000,
        imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500',
        shopId: 13,
        shopName: 'Bánh Tráng Cuộn Cô Ba',
        categoryId: 4,
        categoryName: 'Ăn vặt KTX',
        isAvailable: true,
        isShopOpen: true,
      ),

      // 5. Cơm Tấm Dì Năm
      ProductModel(
        id: 101,
        name: 'Cơm sườn bì chả đặc biệt KTX',
        description: 'Cơm tấm thơm nóng dẻo, sườn nướng mật ong đậm vị thảo mộc, chả trứng hấp vàng óng và bì heo giòn dai cùng mỡ hành béo ngậy.',
        price: 35000,
        imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500',
        shopId: 1,
        shopName: 'Cơm Tấm Dì Năm - KTX B',
        categoryId: 1,
        categoryName: 'Cơm trưa (Hot)',
        isAvailable: true,
        isShopOpen: true,
      ),

      // 6. Bánh mì thịt nướng
      ProductModel(
        id: 104,
        name: 'Bánh mì thịt nướng pate bơ tỏi',
        description: 'Bánh mì giòn rụm nướng nóng hổi, nhân thịt nướng xiên mè, pate béo gan heo tươi tự làm, dưa leo chua giòn và ớt cay.',
        price: 22000,
        imageUrl: 'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=500',
        shopId: 4,
        shopName: 'Bánh Mì Bác Ba - Trạm Xe Buýt B',
        categoryId: 5,
        categoryName: 'Bánh mì',
        isAvailable: true,
        isShopOpen: true,
      ),
    ];
  }
}
