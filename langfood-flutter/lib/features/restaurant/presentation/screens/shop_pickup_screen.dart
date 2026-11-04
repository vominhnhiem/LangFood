import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../../config/config_url.dart';
import '../../../../core/network/api_client.dart';
import '../../../../providers/auth_provider.dart';

class ShopPickupScreen extends StatefulWidget {
  const ShopPickupScreen({
    super.key,
    required this.shopId,
  });

  final int shopId;

  @override
  State<ShopPickupScreen> createState() => _ShopPickupScreenState();
}

class _ShopPickupScreenState extends State<ShopPickupScreen> {
  final _address = TextEditingController();
  LatLng? _pin;
  bool _saving = false;
  late Future<void> _loading;

  String get _endpoint => 'api/Shops/${widget.shopId}/pickup';

  @override
  void initState() {
    super.initState();
    _loading = _load();
  }

  Future<void> _load() async {
    final data = ApiClient.decodeResponse(await ApiClient.get(_endpoint))
        as Map<String, dynamic>;
    if (!mounted) return;
    _address.text = data['address'] as String? ?? '';
    final lat = data['latitude'];
    final lng = data['longitude'];
    if (lat is num && lng is num) {
      _pin = LatLng(lat.toDouble(), lng.toDouble());
    }
  }

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final pin = _pin;
    final address = _address.text.trim();
    if (_saving || pin == null) return;
    final token = context.read<AuthProvider>().accessToken;
    if (token == null || token.isEmpty) {
      _showMessage('Đăng xuất và đăng nhập lại để lưu điểm lấy món.');
      return;
    }
    if (address.isEmpty) {
      _showMessage('Nhập địa chỉ điểm lấy món.');
      return;
    }
    setState(() => _saving = true);
    try {
      final response = await ApiClient.put(
        _endpoint,
        token: token,
        body: {
          'address': address,
          'latitude': pin.latitude,
          'longitude': pin.longitude,
        },
      );
      if (!mounted) return;
      if (response.statusCode == 401) {
        _showMessage('Phiên đã hết hạn. Đăng nhập lại để lưu điểm lấy món.');
        return;
      }
      ApiClient.decodeResponse(response);
      if (!mounted) return;
      _showMessage('Đã lưu điểm lấy món.');
      Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        _showMessage(error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Điểm lấy món của quán')),
    body: SafeArea(
      child: FutureBuilder<void>(
        future: _loading,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: TextButton(
                onPressed: () => setState(() => _loading = _load()),
                child: const Text('Không tải được điểm lấy món. Thử lại'),
              ),
            );
          }
          final pin = _pin;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _address,
                  enabled: !_saving,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'Địa chỉ cửa quán',
                    helperText: 'Chạm lên bản đồ để ghim điểm lấy món.',
                  ),
                ),
              ),
              Expanded(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: pin ?? const LatLng(10.8800, 106.8050),
                    initialZoom: 16,
                    onTap: (_, point) {
                      if (!_saving) setState(() => _pin = point);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: ConfigUrl.mapTileUrl,
                      fallbackUrl: ConfigUrl.mapTileFallbackUrl,
                      userAgentPackageName: 'com.langfood.app',
                    ),
                    if (pin != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: pin,
                            child: const Icon(Icons.location_on, size: 36),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton(
                  onPressed: _saving || pin == null ? null : _save,
                  child: Text(_saving ? 'Đang lưu…' : 'Lưu điểm lấy món'),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}
