import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/display_format.dart';
import '../../../../core/widgets/action_helpers.dart';
import '../../../../data/services/wallet_service.dart';
import '../../../../providers/auth_provider.dart';

class WalletScreen extends StatefulWidget {
  final WalletService? service;
  const WalletScreen({super.key, this.service});
  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late final _service = widget.service ?? WalletService();
  WalletSnapshot? _data;
  bool _loading = true;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) {
      setState(() {
        _loading = false;
        _error = 'Vui lòng đăng nhập.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.load(userId);
      if (mounted) setState(() => _data = data);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _request(bool withdraw) async {
    final user = context.read<AuthProvider>().user;
    if (user == null || _busy || _data == null) return;
    setState(() => _busy = true);
    try {
      final details = await showDialog<_WalletRequest>(
        context: context,
        builder: (_) => _WalletRequestDialog(
          withdraw: withdraw,
          isSeller: user.isSeller,
          balance: _data!.balance,
        ),
      );
      if (!mounted || details == null) return;
      if (!await confirmAction(
        context,
        'Xác nhận yêu cầu',
        '${withdraw ? 'Rút' : 'Nạp'} ${money(details.amount)}? Yêu cầu sẽ được admin xử lý.',
      ))
        return;
      if (!mounted) return;
      if (withdraw) {
        await _service.withdraw(
          user.id,
          amount: details.amount,
          bank: details.bank,
          account: details.account,
          owner: details.owner,
        );
      } else {
        await _service.deposit(user.id, details.amount);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi yêu cầu, đang chờ admin xử lý.')),
      );
      await _load();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorText(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _status(dynamic status) => switch (status) {
    0 => 'Chờ xử lý',
    1 => 'Thành công',
    2 => 'Từ chối',
    _ => 'Chưa xác định',
  };
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Ví và giao dịch'),
      actions: [
        IconButton(
          onPressed: _busy ? null : _load,
          icon: const Icon(Icons.refresh),
        ),
      ],
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
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text('Số dư hiện tại'),
                        Text(
                          money(_data!.balance),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        Wrap(
                          spacing: 12,
                          children: [
                            FilledButton.icon(
                              onPressed: _busy ? null : () => _request(false),
                              icon: const Icon(Icons.add),
                              label: const Text('Nạp tiền'),
                            ),
                            OutlinedButton(
                              onPressed: _busy ? null : () => _request(true),
                              child: const Text('Rút tiền'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Lịch sử giao dịch',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (_data!.transactions.isEmpty)
                  const ListTile(title: Text('Chưa có giao dịch.')),
                ..._data!.transactions.map(
                  (row) => Card(
                    child: ListTile(
                      title: Text(
                        row['description']?.toString() ??
                            row['type']?.toString() ??
                            'Giao dịch',
                      ),
                      subtitle: Text(
                        '${_status(row['status'])}\n${dateText(row['createdAt'])}',
                      ),
                      trailing: Text(
                        money(row['amount'] as num?),
                        style: TextStyle(
                          color: (row['amount'] as num? ?? 0) < 0
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Yêu cầu rút tiền',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (_data!.withdrawals.isEmpty)
                  const ListTile(title: Text('Chưa có yêu cầu rút.')),
                ..._data!.withdrawals.map(
                  (row) => Card(
                    child: ListTile(
                      title: Text(
                        '${money(row['amount'] as num?)} • ${_status(row['status'])}',
                      ),
                      subtitle: Text(
                        '${row['bankName'] ?? ''} • ${row['bankAccountNumber'] ?? ''}\n${dateText(row['createdAt'])}${row['adminNote'] == null ? '' : '\n${row['adminNote']}'}',
                      ),
                      trailing: row['adminBillImageUrl'] == null
                          ? null
                          : IconButton(
                              tooltip: 'Xem biên lai',
                              icon: const Icon(Icons.receipt_long),
                              onPressed: () => showDialog(
                                context: context,
                                builder: (_) => Dialog(
                                  child: InteractiveViewer(
                                    child: Image.network(
                                      ApiClient.resolveImageUrl(
                                        row['adminBillImageUrl'].toString(),
                                      ),
                                      errorBuilder: (_, __, ___) =>
                                          const Padding(
                                            padding: EdgeInsets.all(20),
                                            child: Text(
                                              'Không tải được ảnh biên lai.',
                                            ),
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
  );
}

class _WalletRequest {
  final double amount;
  final String bank;
  final String account;
  final String owner;
  _WalletRequest(this.amount, this.bank, this.account, this.owner);
}

class _WalletRequestDialog extends StatefulWidget {
  final bool withdraw;
  final bool isSeller;
  final double balance;
  const _WalletRequestDialog({
    required this.withdraw,
    required this.isSeller,
    required this.balance,
  });
  @override
  State<_WalletRequestDialog> createState() => _WalletRequestDialogState();
}

class _WalletRequestDialogState extends State<_WalletRequestDialog> {
  final _amount = TextEditingController();
  final _bank = TextEditingController();
  final _account = TextEditingController();
  final _owner = TextEditingController();
  final _form = GlobalKey<FormState>();
  @override
  void dispose() {
    _amount.dispose();
    _bank.dispose();
    _account.dispose();
    _owner.dispose();
    super.dispose();
  }

  String? _required(String? value) =>
      value?.trim().isNotEmpty == true ? null : 'Không được để trống';
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.withdraw ? 'Yêu cầu rút tiền' : 'Yêu cầu nạp tiền'),
    content: SingleChildScrollView(
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.withdraw
                  ? 'Tối thiểu 50.000đ. Số dư sẽ bị trừ khi gửi yêu cầu; admin chuyển khoản thủ công.'
                  : 'Yêu cầu cần admin đối soát và duyệt. Gửi yêu cầu chưa làm tăng số dư ví.',
            ),
            if (widget.withdraw && widget.isSeller)
              const Text('Quán phải duy trì ít nhất 1.000.000đ trong ví.'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amount,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Số tiền (VND)'),
              validator: (s) {
                final value = double.tryParse(s ?? '');
                if (value == null || !value.isFinite || value <= 0)
                  return 'Nhập số tiền hợp lệ';
                if (widget.withdraw && value < 50000)
                  return 'Tối thiểu 50.000đ';
                if (widget.withdraw && value > widget.balance)
                  return 'Số dư không đủ';
                if (widget.withdraw &&
                    widget.isSeller &&
                    widget.balance - value < 1000000)
                  return 'Cần giữ lại 1.000.000đ';
                return null;
              },
            ),
            if (widget.withdraw) ...[
              TextFormField(
                controller: _bank,
                decoration: const InputDecoration(labelText: 'Ngân hàng'),
                validator: _required,
              ),
              TextFormField(
                controller: _account,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Số tài khoản'),
                validator: _required,
              ),
              TextFormField(
                controller: _owner,
                decoration: const InputDecoration(
                  labelText: 'Tên chủ tài khoản',
                ),
                validator: _required,
              ),
            ],
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Quay lại'),
      ),
      FilledButton(
        onPressed: () {
          if (!_form.currentState!.validate()) return;
          FocusScope.of(context).unfocus();
          Navigator.pop(
            context,
            _WalletRequest(
              double.parse(_amount.text),
              _bank.text,
              _account.text,
              _owner.text,
            ),
          );
        },
        child: const Text('Tiếp tục'),
      ),
    ],
  );
}
