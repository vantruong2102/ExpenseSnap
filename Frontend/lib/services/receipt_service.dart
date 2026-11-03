import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../core/constants/api_constants.dart';
import '../models/receipt.dart';
import 'api_exception.dart';
import 'auth_service.dart';

class ReceiptService {
  ReceiptService({http.Client? client, AuthSession? session})
    : _client = client ?? http.Client(),
      _session = session ?? AuthSession.instance;

  final http.Client _client;
  final AuthSession _session;

  String _requireToken() {
    final token = _session.accessToken;
    if (token == null) {
      throw const ApiException('Phiên đăng nhập đã hết. Vui lòng đăng nhập lại.');
    }
    return token;
  }

  /// Receipts of the signed-in user, newest first.
  Future<List<Receipt>> listReceipts() async {
    final token = _requireToken();
    final http.Response response;
    try {
      response = await _client
          .get(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.receipts}'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(ApiConstants.timeout);
    } on TimeoutException {
      throw ApiException.network;
    } on http.ClientException {
      throw ApiException.network;
    }

    if (response.statusCode != 200) throw ApiException.fromResponse(response);
    final body = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    return body.map((item) => Receipt.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<Receipt> uploadReceipt(XFile image) async {
    final token = _requireToken();

    final request = http.MultipartRequest('POST', Uri.parse('${ApiConstants.baseUrl}${ApiConstants.receipts}'))
      ..headers['Authorization'] = 'Bearer $token'
      // readAsBytes works on mobile, desktop and web alike
      ..files.add(http.MultipartFile.fromBytes('image', await image.readAsBytes(), filename: image.name));

    final http.Response response;
    try {
      final streamed = await _client.send(request).timeout(ApiConstants.timeout);
      response = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw ApiException.network;
    } on http.ClientException {
      throw ApiException.network;
    }

    if (response.statusCode != 201) throw ApiException.fromResponse(response);
    return Receipt.fromJson(jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
  }
}
