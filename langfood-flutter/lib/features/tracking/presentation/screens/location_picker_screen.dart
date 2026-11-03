import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../data/services/location_service.dart';

class DeliveryLocation {
  final String address;
  final LatLng coordinates;
  const DeliveryLocation(this.address, this.coordinates);
}

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});
  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _map = MapController();
  final _address = TextEditingController();
  LatLng? _selected;
  bool _locating = false;
  String? _error;
  // Only the initial viewport; never used as a delivery point without selection.
  static const _campus = LatLng(10.8805, 106.8048);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _address.dispose();
    _map.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    setState(() {
      _locating = true;
      _error = null;
    });
    try {
      final position = await LocationService.current();
      if (!mounted) return;
      final point = LatLng(position.latitude, position.longitude);
      setState(() => _selected = point);
      _map.move(point, 17);
    } catch (e) {
      if (mounted)
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Chọn điểm giao hàng')),
    body: Column(
      children: [
        Expanded(
          child: FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _campus,
              initialZoom: 15,
              onTap: (_, point) => setState(() => _selected = point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.langfood_flutter',
              ),
              if (_selected != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selected!,
                      width: 48,
                      height: 48,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 42,
                      ),
                    ),
                  ],
                ),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: _locating ? null : _locate,
                icon: _locating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
                label: const Text('Lấy vị trí hiện tại'),
              ),
              Text(
                _selected == null
                    ? 'Chạm bản đồ để chọn điểm giao.'
                    : '${_selected!.latitude.toStringAsFixed(6)}, ${_selected!.longitude.toStringAsFixed(6)}',
              ),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
              TextField(
                controller: _address,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ / tòa nhà / phòng nhận',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _selected == null || _address.text.trim().isEmpty
                    ? null
                    : () => Navigator.pop(
                        context,
                        DeliveryLocation(_address.text.trim(), _selected!),
                      ),
                child: const Text('Xác nhận điểm giao'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
