import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/display_format.dart';
import '../../../../core/widgets/action_helpers.dart';
import '../../../../data/models/category_model.dart';
import '../../../../data/models/product_model.dart';
import '../../../../data/services/product_service.dart';
import '../../../../providers/auth_provider.dart';

class MerchantProductsScreen extends StatefulWidget {
  final ProductService? service;
  const MerchantProductsScreen({super.key, this.service});
  @override
  State<MerchantProductsScreen> createState() => _MerchantProductsScreenState();
}

class _MerchantProductsScreenState extends State<MerchantProductsScreen> {
  late final _service = widget.service ?? ProductService();
  List<ProductModel> _products = [];
  bool _loading = true;
  int? _deleting;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = context.read<AuthProvider>().user;
    if (user?.isSeller != true || user?.shopId == null) {
      setState(() {
        _loading = false;
        _error = 'Tài khoản chưa được gán quán ăn.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final products = await _service.getProductsByShop(user!.shopId!);
      if (mounted) setState(() => _products = products);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit([ProductModel? product]) async {
    final shopId = context.read<AuthProvider>().user?.shopId;
    if (shopId == null) return;
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ProductEditorScreen(
          shopId: shopId,
          product: product,
          service: _service,
        ),
      ),
    );
    if (saved == true && mounted) _load();
  }

  Future<void> _delete(ProductModel product) async {
    if (_deleting != null) return;
    if (!await confirmAction(
          context,
          'Xóa món?',
          'Xóa "${product.name}" khỏi menu?',
          label: 'Xóa món',
        ) ||
        !mounted)
      return;
    setState(() => _deleting = product.id);
    try {
      await _service.deleteProduct(product.id);
      if (mounted) await _load();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorText(e))));
    } finally {
      if (mounted) setState(() => _deleting = null);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Quản lý menu'),
      actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
    ),
    floatingActionButton: context.watch<AuthProvider>().user?.shopId == null
        ? null
        : FloatingActionButton.extended(
            onPressed: () => _edit(),
            icon: const Icon(Icons.add),
            label: const Text('Thêm món'),
          ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!),
                TextButton(onPressed: _load, child: const Text('Thử lại')),
              ],
            ),
          )
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                if (_products.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('Quán chưa có món ăn.')),
                  ),
                ..._products.map(
                  (product) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                ApiClient.resolveImageUrl(product.imageUrl),
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const SizedBox(
                                  width: 56,
                                  child: Icon(Icons.restaurant),
                                ),
                              ),
                            ),
                            title: Text(product.name),
                            subtitle: Text(
                              '${money(product.price)}\n${product.statusLabel} • ${product.isAvailable ? 'Còn bán' : 'Ngừng bán'}',
                            ),
                          ),
                          Wrap(
                            spacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _deleting != null
                                    ? null
                                    : () => _edit(product),
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('Sửa'),
                              ),
                              TextButton.icon(
                                onPressed: _deleting != null
                                    ? null
                                    : () => _delete(product),
                                icon: const Icon(Icons.delete_outline),
                                label: const Text('Xóa'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
  );
}

class ProductEditorScreen extends StatefulWidget {
  final int shopId;
  final ProductModel? product;
  final ProductService service;
  const ProductEditorScreen({
    super.key,
    required this.shopId,
    this.product,
    required this.service,
  });
  @override
  State<ProductEditorScreen> createState() => _ProductEditorScreenState();
}

class _ProductEditorScreenState extends State<ProductEditorScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _description = TextEditingController();
  final _url = TextEditingController();
  List<CategoryModel> _categories = [];
  int? _categoryId;
  Uint8List? _image;
  String? _filename;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _name.text = product?.name ?? '';
    _price.text = product?.price.toStringAsFixed(0) ?? '';
    _description.text = product?.description ?? '';
    _url.text = product?.imageUrl ?? '';
    _categoryId = product?.categoryId;
    _loadCategories();
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _description.dispose();
    _url.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final categories = await widget.service.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        if (!categories.any((c) => c.id == _categoryId)) _categoryId = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pick() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (image == null || !mounted) return;
      if (await image.length() > 5 * 1024 * 1024)
        throw Exception('Ảnh không được vượt quá 5 MB.');
      final bytes = await image.readAsBytes();
      if (mounted)
        setState(() {
          _image = bytes;
          _filename = image.name;
          _url.clear();
        });
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorText(e))));
    }
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate() || _categoryId == null)
      return;
    setState(() => _saving = true);
    try {
      await widget.service.saveProduct(
        existing: widget.product,
        shopId: widget.shopId,
        categoryId: _categoryId!,
        name: _name.text,
        price: double.parse(_price.text),
        description: _description.text,
        imageUrl: _url.text,
        imageBytes: _image,
        imageName: _filename,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã lưu món ăn.')));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorText(e))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.product == null ? 'Thêm món' : 'Sửa món'),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(
            child: TextButton(
              onPressed: _loadCategories,
              child: Text('$_error • Thử lại'),
            ),
          )
        : Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (widget.product != null)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Sau khi sửa, món cần được quản trị viên duyệt lại. Có thể thay ảnh bằng URL.',
                    ),
                  ),
                if (_image != null)
                  Image.memory(_image!, height: 180, fit: BoxFit.cover)
                else if (_url.text.isNotEmpty)
                  Image.network(
                    ApiClient.resolveImageUrl(_url.text),
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(
                      height: 80,
                      child: Center(
                        child: Text('Không tải được ảnh xem trước.'),
                      ),
                    ),
                  ),
                if (widget.product == null)
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _pick,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Chọn ảnh để tải lên'),
                  ),
                TextFormField(
                  controller: _url,
                  enabled: !_saving,
                  decoration: const InputDecoration(
                    labelText: 'URL ảnh',
                    helperText: 'Ảnh có sẵn trên mạng hoặc chọn ảnh tải lên khi thêm món',
                  ),
                  onChanged: (_) {
                    if (_url.text.isNotEmpty) setState(() => _image = null);
                  },
                  validator: (s) {
                    if (_image != null) return null;
                    if (widget.product?.imageUrl == s && s?.isNotEmpty == true)
                      return null;
                    final uri = Uri.tryParse(s?.trim() ?? '');
                    return uri != null &&
                            uri.hasAuthority &&
                            ['http', 'https'].contains(uri.scheme)
                        ? null
                        : 'Chọn ảnh hoặc nhập URL HTTP/HTTPS hợp lệ';
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _name,
                  enabled: !_saving,
                  decoration: const InputDecoration(labelText: 'Tên món'),
                  validator: (s) =>
                      s?.trim().isNotEmpty == true ? null : 'Nhập tên món',
                ),
                TextFormField(
                  controller: _price,
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Giá (VND)'),
                  validator: (s) {
                    final value = double.tryParse(s ?? '');
                    return value != null && value.isFinite && value > 0
                        ? null
                        : 'Giá phải lớn hơn 0';
                  },
                ),
                DropdownButtonFormField<int>(
                  initialValue: _categoryId,
                  decoration: const InputDecoration(labelText: 'Danh mục'),
                  items: _categories
                      .map(
                        (c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name)),
                      )
                      .toList(),
                  onChanged: _saving
                      ? null
                      : (id) => setState(() => _categoryId = id),
                  validator: (id) =>
                      id == null ? 'Chọn danh mục có trong hệ thống' : null,
                ),
                if (_categories.isEmpty)
                  const Text(
                    'Chưa có danh mục. Liên hệ quản trị viên để bổ sung.',
                  ),
                TextFormField(
                  controller: _description,
                  enabled: !_saving,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Mô tả'),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving || _categories.isEmpty ? null : _save,
                  child: Text(_saving ? 'Đang lưu...' : 'Lưu món'),
                ),
              ],
            ),
          ),
  );
}
