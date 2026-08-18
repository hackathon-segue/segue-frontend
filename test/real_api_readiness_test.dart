import 'package:flutter_test/flutter_test.dart';
import 'package:segue_frontend/exceptions/app_exception.dart';
import 'package:segue_frontend/models/models.dart';
import 'package:segue_frontend/providers/providers.dart';
import 'package:segue_frontend/repositories/repositories.dart';

/// Fakes [SegueApiClient] directly (no real network I/O) so these tests run
/// against the exact same `RealSegueRepository` used when
/// `USE_MOCK_DATA=false`, proving the real-API path is wired end-to-end
/// before a live backend exists to test against.
class _FakeApiClient implements SegueApiClient {
  _FakeApiClient({this.getResponse, this.getError});

  final Object? getResponse;
  final Object? getError;

  @override
  Future<Object?> getJson(
    String path, {
    Map<String, Object?> queryParameters = const <String, Object?>{},
  }) async {
    if (getError != null) {
      throw getError!;
    }
    return getResponse;
  }

  @override
  Future<Object?> postJson(String path, {JsonMap body = const <String, Object?>{}}) async {
    throw UnimplementedError();
  }

  @override
  Future<Object?> patchJson(String path, {JsonMap body = const <String, Object?>{}}) async {
    throw UnimplementedError();
  }
}

void main() {
  group('RealSegueRepository against a live-shaped API client', () {
    test('maps a successful /api/customers/lookup response to Customer', () async {
      final RealSegueRepository repo = RealSegueRepository(
        apiClient: _FakeApiClient(
          getResponse: <String, Object?>{
            'id': 1,
            'name': '김세계',
            'phoneNumber': '010-1234-5678',
            'hasConsented': true,
          },
        ),
      );

      final Customer customer = await repo.lookupCustomerByPhone('010-1234-5678');

      expect(customer.id, 1);
      expect(customer.hasConsented, isTrue);
    });

    test('a network failure (backend unreachable) surfaces as an AppException, not a crash', () async {
      final RealSegueRepository repo = RealSegueRepository(
        apiClient: _FakeApiClient(getError: const AppException('Connection refused')),
      );

      expect(() => repo.lookupCustomerByPhone('010-1234-5678'), throwsA(isA<AppException>()));
    });

    test('a 403 CONSENT_REQUIRED response maps to ApiException.isConsentRequired', () async {
      final RealSegueRepository repo = RealSegueRepository(
        apiClient: _FakeApiClient(
          getError: const ApiException(
            '고객 동의가 필요합니다.',
            statusCode: 403,
            code: 'CONSENT_REQUIRED',
          ),
        ),
      );

      try {
        await repo.lookupCustomerByPhone('010-9876-5432');
        fail('expected ApiException');
      } on ApiException catch (e) {
        expect(e.isConsentRequired, isTrue);
      }
    });
  });

  group('StaffWebSessionController against RealSegueRepository', () {
    test('a network failure during lookup resolves to AsyncValue.error, never an uncaught exception', () async {
      final RealSegueRepository repo = RealSegueRepository(
        apiClient: _FakeApiClient(getError: const AppException('Connection refused')),
      );
      final StaffWebSessionController controller = StaffWebSessionController(repository: repo);

      // Must not throw out of the controller — the try/catch in
      // lookupCustomer() is what makes real network failures safe to hit
      // from the UI instead of crashing the app.
      await controller.lookupCustomer('010-1234-5678');

      expect(controller.state.lookupState.hasError, isTrue);
      expect(controller.state.customer, isNull);
    });
  });
}
