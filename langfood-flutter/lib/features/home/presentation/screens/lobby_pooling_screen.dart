import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/display_format.dart';
import '../../../../core/widgets/langfood_card.dart';
import '../../../../data/models/lobby_room.dart';
import '../../../../providers/auth_provider.dart';
import '../../../shop/presentation/screens/shop_menu_screen.dart';
import '../../../tracking/presentation/screens/live_tracking_screen.dart';
import '../../../tracking/presentation/screens/location_picker_screen.dart';

class LobbyPoolingScreen extends StatefulWidget {
  const LobbyPoolingScreen({super.key, required this.shops});

  final Map<int, String> shops;

  @override
  State<LobbyPoolingScreen> createState() => _LobbyPoolingScreenState();
}

class _LobbyPoolingScreenState extends State<LobbyPoolingScreen> {
  List<LobbyRoom> _rooms = [];
  String? _building;
  String? _error;
  bool _loading = false;
  bool _saving = false;
  Timer? _timer;
  int _ticks = 0;

  String? get _token => context.read<AuthProvider>().accessToken;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {});
      if (++_ticks % 5 == 0) _refresh();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_loading) return;
    final token = _token;
    if (token == null) {
      setState(() => _error = 'Đăng xuất và đăng nhập lại để dùng Đặt chung.');
      return;
    }
    _loading = true;
    try {
      final response = await ApiClient.get('api/Lobby', token: token);
      if (response.statusCode == 401)
        throw Exception('Phiên hết hạn. Hãy đăng nhập lại.');
      if (response.statusCode == 403)
        throw Exception('Tài khoản sinh viên cần có tòa KTX đang hoạt động.');
      final data = ApiClient.decodeResponse(response) as Map<String, dynamic>;
      final name = data['buildingName'] as String;
      final rooms = (data['rooms'] as List)
          .map((row) => LobbyRoom.fromJson(row as Map<String, dynamic>))
          .toList();
      if (mounted)
        setState(() {
          _building = name;
          _rooms = rooms;
          _error = null;
        });
    } catch (error) {
      if (mounted)
        setState(
          () => _error = error.toString().replaceFirst('Exception: ', ''),
        );
    } finally {
      _loading = false;
    }
  }

  Future<void> _openRoom(String building) async {
    final shop = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('Chọn quán để mở phòng 10 phút')),
            for (final shop in widget.shops.entries)
              ListTile(
                title: Text(shop.value),
                onTap: () => Navigator.pop(context, shop.key),
              ),
          ],
        ),
      ),
    );
    if (!mounted || shop == null) return;
    final location = await Navigator.push<CampusDeliveryLocation>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          returnResult: true,
          lobbyBuildingName: building,
        ),
      ),
    );
    if (!mounted || location == null) return;
    await _write(
      () => ApiClient.post(
        'api/Lobby',
        token: _token,
        body: {
          'shopId': shop,
          'latitude': location.position.latitude,
          'longitude': location.position.longitude,
        },
      ),
    );
  }

  Future<void> _write(Future<http.Response> Function() request) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final response = await request();
      if (response.statusCode == 401)
        throw Exception('Phiên hết hạn. Hãy đăng nhập lại.');
      ApiClient.decodeResponse(response);
      await _refresh();
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _cancel(LobbyRoom room, {required bool wholeRoom}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(wholeRoom ? 'Hủy phòng gom đơn?' : 'Hủy phần của bạn?'),
        content: Text(
          wholeRoom ? 'Phòng sẽ đóng cho tất cả thành viên và không tạo đơn.' : 'Phần của bạn sẽ được rút khỏi phòng. Bạn có thể tham gia lại khi phòng còn mở.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Quay lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận hủy'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    final endpoint = 'api/Lobby/${room.id}';
    await _write(
      () => ApiClient.delete(
        wholeRoom ? endpoint : '$endpoint/portion',
        token: _token,
      ),
    );
  }

  Future<void> _finalize(LobbyRoom room) async {
    final quote = room.hostShippingQuote;
    if (quote == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chốt phòng và đặt COD?'),
        content: Text(
          'Chốt ${room.participants} phần đã xác nhận. Phí ship phần của bạn là '
          '${money(quote)}. Bạn nhận cả chuyến tại sảnh và thanh toán COD cho '
          'shipper, gồm tiền món của cả nhóm và tổng phí ship 10.000đ.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Quay lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Chốt và đặt đơn'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    await _write(
      () => ApiClient.post(
        'api/Lobby/${room.id}/finalize',
        token: _token,
        queryParams: {'expectedParticipants': room.participants.toString()},
      ),
    );
  }

  Future<void> _join(LobbyRoom room) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ShopMenuScreen(
          shopId: room.shopId,
          initialShopName: room.shopName,
          lobbyRoom: room,
        ),
      ),
    );
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final building = _building;
    final visibleRooms = _rooms.where(
      (room) =>
          room.orderId != null ||
          (room.isOpen && room.closesAt.isAfter(DateTime.now())),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phòng Gom Đơn Sảnh KTX'),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_error != null) Text(_error!),
            if (building == null && _error == null)
              const Center(child: CircularProgressIndicator()),
            if (building != null) ...[
              LangFoodCard(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                showShadow: false,
                showBorder: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sảnh $building',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '4 người: 2.500đ/người • 5 người: 2.000đ/người. Chủ phòng nhận và thanh toán COD cả chuyến.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _saving || widget.shops.isEmpty
                    ? null
                    : () => _openRoom(building),
                icon: const Icon(Icons.add),
                label: const Text('Mở phòng gom đơn mới tại sảnh'),
              ),
              if (visibleRooms.isEmpty) const Text('Chưa có phòng trong tòa.'),
              for (final room in visibleRooms) _roomCard(room),
            ],
          ],
        ),
      ),
    );
  }

  Widget _roomCard(LobbyRoom room) {
    final remaining = room.closesAt
        .difference(DateTime.now())
        .inSeconds
        .clamp(0, 600);
    final open = room.isOpen && remaining > 0;
    final minutes = (remaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (remaining % 60).toString().padLeft(2, '0');
    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(room.shopName, style: Theme.of(context).textTheme.titleMedium),
            Text(room.address),
            Text(
              open
                  ? 'Còn $minutes:$seconds'
                  : room.orderId == null
                  ? 'Phòng đã đóng'
                  : 'Đã chốt chuyến',
            ),
            Text('${room.participants}/5 phần đã xác nhận'),
            const SizedBox(height: 4),
            LinearProgressIndicator(value: room.participants / 5),
            if (room.foodTotal case final food?)
              Text('Tiền món của bạn: ${money(food)}'),
            if (room.shippingShare case final share?)
              Text('Phí ship của bạn: ${money(share)}'),
            if (room.portionNumber case final number?)
              Text('Mã nhận món: Phần $number'),
            if (open && (room.joined || room.participants < 5))
              FilledButton.tonal(
                onPressed: () => _join(room),
                child: Text(
                  room.joined ? 'Cập nhật phần của bạn' : 'Chọn món tham gia',
                ),
              ),
            if (open && room.canCancel)
              FilledButton(
                onPressed:
                    _saving ||
                        !room.canFinalize ||
                        room.hostShippingQuote == null
                    ? null
                    : () => _finalize(room),
                child: const Text('Đặt sớm'),
              ),
            if (open && room.canCancel && !room.canFinalize)
              const Text(
                'Chủ phòng cần chọn món và xác nhận phần của mình trước.',
              ),
            if (open && room.joined)
              TextButton(
                onPressed: _saving
                    ? null
                    : () => _cancel(room, wholeRoom: false),
                child: const Text('Hủy phần của tôi'),
              ),
            if (open && room.canCancel)
              TextButton(
                onPressed: _saving
                    ? null
                    : () => _cancel(room, wholeRoom: true),
                child: const Text('Hủy phòng gom đơn'),
              ),
            if (room.orderId case final orderId?)
              TextButton(
                onPressed: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LiveTrackingScreen(orderId: orderId),
                  ),
                ),
                child: const Text('Theo dõi chuyến'),
              ),
          ],
        ),
      ),
    );
  }
}
