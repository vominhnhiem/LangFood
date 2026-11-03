import '../../core/network/api_client.dart';

class WalletSnapshot {
  final double balance;
  final List<Map<String, dynamic>> transactions;
  final List<Map<String, dynamic>> withdrawals;
  WalletSnapshot(this.balance, this.transactions, this.withdrawals);
}

class WalletService {
  Future<WalletSnapshot> load(String userId) async {
    final wallet = ApiClient.decodeResponse(
      await ApiClient.get('api/Wallet/user/$userId'),
    ) as Map;
    if (wallet['balance'] is! num)
      throw Exception('Không đọc được số dư từ máy chủ.');
    final results = await Future.wait([
      ApiClient.get('api/Wallet/transactions/$userId'),
      ApiClient.get('api/Wallet/withdrawal-history/$userId'),
    ]);
    return WalletSnapshot(
      (wallet['balance'] as num).toDouble(),
      (ApiClient.decodeResponse(results[0]) as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
      (ApiClient.decodeResponse(results[1]) as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
    );
  }

  Future<void> deposit(String userId, double amount) async {
    if (!amount.isFinite || amount <= 0)
      throw Exception('Số tiền nạp phải lớn hơn 0.');
    ApiClient.decodeResponse(
      await ApiClient.post(
        'api/Wallet/deposit',
        queryParams: {'userId': userId, 'amount': amount},
      ),
    );
  }

  Future<void> withdraw(
    String userId, {
    required double amount,
    required String bank,
    required String account,
    required String owner,
  }) async {
    if (!amount.isFinite || amount < 50000)
      throw Exception('Số tiền rút tối thiểu 50.000đ.');
    if ([bank, account, owner].any((s) => s.trim().isEmpty))
      throw Exception('Nhập đầy đủ thông tin ngân hàng.');
    ApiClient.decodeResponse(
      await ApiClient.post(
        'api/Wallet/withdrawal-request',
        body: {
          'userId': userId,
          'amount': amount,
          'bankName': bank.trim(),
          'bankAccountNumber': account.trim(),
          'bankAccountName': owner.trim(),
        },
      ),
    );
  }
}
