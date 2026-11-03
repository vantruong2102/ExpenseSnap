import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/utils/validators.dart';
import 'package:frontend/models/receipt.dart';
import 'package:frontend/screens/receipt_preview/receipt_preview_screen.dart';
import 'package:frontend/screens/register/register_screen.dart';
import 'package:frontend/services/api_exception.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/receipt_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';

// 1x1 transparent PNG
final _pngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
);

class _FakeReceiptService extends ReceiptService {
  _FakeReceiptService({this.error});

  final ApiException? error;
  int uploadCount = 0;

  @override
  Future<Receipt> uploadReceipt(XFile image) async {
    uploadCount++;
    if (error != null) throw error!;
    return Receipt(id: 1, imageUrl: 'http://x/receipt.png', createdAt: DateTime(2026, 11, 3));
  }
}

Future<void> _fillRegisterForm(
  WidgetTester tester, {
  String password = 'ExpenseSnap@2026',
  String confirm = 'ExpenseSnap@2026',
}) async {
  final fields = find.byType(TextField);
  await tester.enterText(fields.at(0), 'Nguyễn Văn Trí');
  await tester.enterText(fields.at(1), 'tri@example.com');
  await tester.enterText(fields.at(2), password);
  await tester.enterText(fields.at(3), confirm);
}

Future<void> _tapRegister(WidgetTester tester) async {
  final button = find.text('Tạo tài khoản');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pump();
}

void main() {
  group('Validators', () {
    test('email', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('abc'), isNotNull);
      expect(Validators.email('tri@example.com'), isNull);
    });

    test('password', () {
      expect(Validators.password('1234567'), isNotNull);
      expect(Validators.password('12345678'), isNotNull);
      expect(Validators.password('ExpenseSnap@2026'), isNull);
    });
  });

  group('RegisterScreen', () {
    testWidgets('shows validation errors for empty form', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));

      await _tapRegister(tester);

      expect(find.text('Vui lòng nhập họ tên'), findsOneWidget);
      expect(find.text('Vui lòng nhập email'), findsOneWidget);
    });

    testWidgets('shows error when passwords do not match', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));

      await _fillRegisterForm(tester, confirm: 'Other@2026x');
      await _tapRegister(tester);

      expect(find.text('Mật khẩu xác nhận không khớp'), findsOneWidget);
    });

    testWidgets('shows server field error when email already exists', (tester) async {
      final client = MockClient((request) async {
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'email': ['Email này đã được sử dụng.'],
            }),
          ),
          400,
          headers: {'content-type': 'application/json'},
        );
      });
      final session = AuthSession.instance..clear();
      await tester.pumpWidget(
        MaterialApp(
          home: RegisterScreen(
            authService: AuthService(client: client, session: session),
          ),
        ),
      );

      await _fillRegisterForm(tester);
      await _tapRegister(tester);
      await tester.pump();

      expect(find.text('Email này đã được sử dụng.'), findsWidgets);
      expect(session.isSignedIn, isFalse);
    });
  });

  group('AuthService', () {
    test('register stores tokens in session', () async {
      final client = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(request.url.path, '/api/auth/register/');
        expect(body['email'], 'tri@example.com');
        return http.Response(
          jsonEncode({
            'user': {'id': 7, 'email': 'tri@example.com', 'full_name': 'Tri'},
            'access': 'access-token',
            'refresh': 'refresh-token',
          }),
          201,
        );
      });
      final session = AuthSession.instance..clear();

      final user = await AuthService(client: client, session: session).register(
        fullName: 'Tri',
        email: ' tri@example.com ',
        password: 'ExpenseSnap@2026',
        passwordConfirm: 'ExpenseSnap@2026',
      );

      expect(user.id, 7);
      expect(session.accessToken, 'access-token');
      session.clear();
    });
  });

  group('ReceiptPreviewScreen', () {
    testWidgets('saves image and returns receipt', (tester) async {
      final service = _FakeReceiptService();
      Receipt? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await Navigator.of(context).push<Receipt>(
                  MaterialPageRoute(
                    builder: (_) => ReceiptPreviewScreen(
                      image: XFile.fromData(_pngBytes, name: 'receipt.png'),
                      receiptService: service,
                    ),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();

      expect(service.uploadCount, 1);
      expect(result?.id, 1);
    });

    testWidgets('shows error and stays on screen when upload fails', (tester) async {
      final service = _FakeReceiptService(error: ApiException.network);
      await tester.pumpWidget(
        MaterialApp(
          home: ReceiptPreviewScreen(
            image: XFile.fromData(_pngBytes, name: 'receipt.png'),
            receiptService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();

      expect(find.text(ApiException.network.message), findsOneWidget);
      expect(find.byType(ReceiptPreviewScreen), findsOneWidget);
    });
  });
}
