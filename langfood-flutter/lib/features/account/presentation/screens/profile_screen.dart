import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/display_format.dart';
import '../../../../core/widgets/langfood_card.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/services/account_service.dart';
import '../../../../data/services/auth_service.dart';
import '../../../../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  final AccountService? service;
  const ProfileScreen({super.key, this.service});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _room = TextEditingController();
  late UserModel _user;
  int? _buildingId;
  List<Map<String, dynamic>> _buildings = [];
  bool _loadingBuildings = true;
  String? _buildingsError;
  bool _saving = false;
  late final _service = widget.service ?? AccountService();
  @override
  void initState() {
    super.initState();
    _user = context.read<AuthProvider>().user!;
    _name.text = _user.fullName ?? '';
    _phone.text = _user.phoneNumber ?? '';
    _room.text = _user.ktxRoom ?? '';
    _buildingId = _user.buildingId;
    _loadBuildings();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _room.dispose();
    super.dispose();
  }

  Future<void> _loadBuildings() async {
    setState(() {
      _loadingBuildings = true;
      _buildingsError = null;
    });
    try {
      final rows = await AuthService().getBuildings();
      if (mounted) setState(() => _buildings = rows);
    } catch (e) {
      if (mounted) setState(() => _buildingsError = errorText(e));
    } finally {
      if (mounted) setState(() => _loadingBuildings = false);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    try {
      final profile = await _service.update(
        _user,
        fullName: _name.text.trim(),
        phone: _phone.text.trim(),
        buildingId: _buildingId,
        room: _room.text.trim(),
      );
      if (!mounted) return;
      await context.read<AuthProvider>().setProfile(profile);
      if (!mounted) return;
      setState(() => _user = profile);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã lưu tài khoản.')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorText(e))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _avatar() async {
    if (_saving) return;
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 80,
      );
      if (image == null || !mounted) return;
      setState(() => _saving = true);
      final url = await _service.uploadAvatar(
        _user.id,
        await image.readAsBytes(),
        image.name,
      );
      if (!mounted) return;
      final updated = _user.copyWith(avatarUrl: url);
      await context.read<AuthProvider>().setProfile(updated);
      if (mounted) setState(() => _user = updated);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorText(e))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasBuilding = _buildings.any(
      (b) => (b['id'] ?? b['Id']) == _buildingId,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Tài khoản')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: CircleAvatar(
                radius: 46,
                child: _user.avatarUrl?.isNotEmpty == true
                    ? ClipOval(
                        child: Image.network(
                          ApiClient.resolveImageUrl(_user.avatarUrl),
                          width: 92,
                          height: 92,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.person, size: 48),
                        ),
                      )
                    : const Icon(Icons.person, size: 48),
              ),
            ),
            TextButton.icon(
              onPressed: _saving ? null : _avatar,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Đổi ảnh đại diện'),
            ),
            LangFoodCard(
              showShadow: false,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _user.username,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                subtitle: Text(
                  [_user.email, _user.roleName].whereType<String>().join(' • '),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Thông tin cá nhân',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _name,
              enabled: !_saving,
              decoration: const InputDecoration(labelText: 'Họ tên'),
              validator: (s) =>
                  s == null || s.trim().isEmpty ? 'Nhập họ tên' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phone,
              enabled: !_saving,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Số điện thoại'),
              validator: (s) => RegExp(r'^0[0-9]{9}$').hasMatch(s ?? '')
                  ? null
                  : 'Nhập số điện thoại 10 chữ số, bắt đầu bằng 0',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              key: ValueKey('building_${_buildingId}_${_buildings.length}'),
              initialValue: hasBuilding ? _buildingId : null,
              decoration: const InputDecoration(
                labelText: 'Tòa nhà (tùy chọn)',
              ),
              items: _buildings
                  .map(
                    (b) => DropdownMenuItem(
                      value: (b['id'] ?? b['Id']) as int,
                      child: Text((b['name'] ?? b['Name']).toString()),
                    ),
                  )
                  .toList(),
              onChanged: _saving || _loadingBuildings
                  ? null
                  : (id) => setState(() => _buildingId = id),
            ),
            if (_loadingBuildings) const LinearProgressIndicator(),
            if (_buildingsError != null)
              TextButton(
                onPressed: _loadBuildings,
                child: Text(
                  'Không tải được tòa nhà. Thử lại. Giữ tòa hiện tại: ${_user.buildingId ?? 'chưa chọn'}.',
                ),
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _room,
              enabled: !_saving,
              decoration: const InputDecoration(
                labelText: 'Phòng / ghi chú nơi ở',
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Đang lưu...' : 'Lưu thay đổi'),
            ),
          ],
        ),
      ),
    );
  }
}
