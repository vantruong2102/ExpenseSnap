import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../core/constants/api_constants.dart';
import '../models/receipt.dart';
import 'api_exception.dart';
import 'auth_service.dart';

class ReceiptService {
  ReceiptService({http.Client? client, AuthSession? session, this.authService})
    : _client = client ?? http.Client(),
      _session = session ?? AuthSession.instance;

  final http.Client _client;
  final AuthSession _session;

  /// Dùng để lấy lại JWT khi hết hạn; mặc định tạo AuthService dùng chung client và session.
  final AuthService? authService;

  /// Receipts of the signed-in user, newest first.
  Future<List<Receipt>> listReceipts() async {
    final response = await _sendAuthorized(
      (token) => _client.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.receipts}'),
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    if (response.statusCode != 200) throw ApiException.fromResponse(response);
    final body = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    return body.map((item) => Receipt.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<Receipt> uploadReceipt(XFile image) async {
    // readAsBytes works on mobile, desktop and web alike
    final bytes = await image.readAsBytes();

    final response = await _sendAuthorized((token) async {
      // MultipartRequest chỉ gửi được một lần, nên tạo mới cho mỗi lần thử
      final request = http.MultipartRequest('POST', Uri.parse('${ApiConstants.baseUrl}${ApiConstants.receipts}'))
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(http.MultipartFile.fromBytes('image', bytes, filename: image.name));
      return http.Response.fromStream(await _client.send(request));
    });

    if (response.statusCode != 201) throw ApiException.fromResponse(response);
    return Receipt.fromJson(jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
  }

  /// Gửi request kèm JWT. Nếu JWT hết hạn (401) thì lấy JWT mới từ phiên Firebase và thử lại một lần.
  Future<http.Response> _sendAuthorized(Future<http.Response> Function(String token) send) async {
    final token = _session.accessToken;
    if (token == null) {
      throw const ApiException('Phiên đăng nhập đã hết. Vui lòng đăng nhập lại.');
    }

    var response = await _withTimeout(send(token));
    if (response.statusCode == 401) {
      final renewer = authService ?? AuthService(client: _client, session: _session);
      await renewer.signInToBackend(forceRefresh: true);
      response = await _withTimeout(send(_session.accessToken!));
    }
    return response;
  }

  Future<http.Response> _withTimeout(Future<http.Response> request) async {
    try {
      return await request.timeout(ApiConstants.timeout);
    } on TimeoutException {
      throw ApiException.network;
    } on http.ClientException {
      throw ApiException.network;
    }
  }
}
