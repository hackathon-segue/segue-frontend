import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:segue_frontend/exceptions/app_exception.dart';
import 'package:segue_frontend/models/models.dart';
import 'package:segue_frontend/repositories/repositories.dart';

void main() {
  test('real repository looks up a staff customer by phone number', () async {
    final _RecordingApiClient apiClient = _RecordingApiClient(
      getResponse: <String, Object?>{
        'id': 1,
        'name': '김세계',
        'phoneNumber': '010-1234-5678',
        'hasConsented': true,
      },
    );
    final RealSegueRepository repository = RealSegueRepository(
      apiClient: apiClient,
    );

    final Customer customer = await repository.lookupCustomerByPhone(
      '010-1234-5678',
    );

    expect(apiClient.lastGetPath, '/api/customers/lookup');
    expect(apiClient.lastGetQueryParameters, <String, Object?>{
      'phoneNumber': '010-1234-5678',
    });
    expect(customer.name, '김세계');
    expect(customer.hasConsented, isTrue);
  });

  test('real repository posts the staff consent decision', () async {
    final _RecordingApiClient apiClient = _RecordingApiClient(
      postResponse: <String, Object?>{
        'customerId': 1,
        'status': 'AGREE',
        'scope': '장바구니 조회, 구매 의도·상담 결과 저장, 고객 모바일 재확인',
        'consentedAt': '2026-08-16T17:30:41',
      },
    );
    final RealSegueRepository repository = RealSegueRepository(
      apiClient: apiClient,
    );

    final CustomerConsent consent = await repository.submitCustomerConsent(
      customerId: 1,
      agreed: true,
    );

    expect(apiClient.lastPostPath, '/api/customers/1/consent');
    expect(apiClient.lastPostBody, <String, Object?>{'agreed': true});
    expect(consent.hasAgreed, isTrue);
  });

  test(
    'real repository posts the API.md cart save body to /api/cart',
    () async {
      final _RecordingApiClient apiClient = _RecordingApiClient(
        postResponse: <String, Object?>{
          'cartItemId': 77,
          'productId': 6,
          'productName': 'Diamond 3D 카프스킨 숄더백',
          'imageUrl': 'https://example.com/diamond.png',
          'category': '가방',
          'skuId': 14,
          'color': '오렌지',
          'size': '스몰',
          'currentStoreInStock': false,
          'otherStoreInStock': false,
          'restockPlanned': false,
          'actionButtonLabel': 'Last Intent 시작',
          'savedAt': '2026-08-16T15:00:00',
        },
      );
      final RealSegueRepository repository = RealSegueRepository(
        apiClient: apiClient,
      );

      final CartItem item = await repository.saveCartItem(
        const CartSaveRequest(
          customerId: 1,
          productId: 6,
          color: '오렌지',
          size: '스몰',
        ),
      );

      expect(apiClient.lastPostPath, '/api/cart');
      expect(apiClient.lastPostBody, <String, Object?>{
        'customerId': 1,
        'productId': 6,
        'color': '오렌지',
        'size': '스몰',
      });
      expect(apiClient.lastPostBody, isNot(contains('skuId')));
      expect(item.skuId, 14);
    },
  );

  test('real repository fetches cart by customerId and storeId', () async {
    final _RecordingApiClient apiClient = _RecordingApiClient(
      getResponse: <Object?>[
        <String, Object?>{
          'cartItemId': 1,
          'productId': 1,
          'productName': 'MCM 백팩 미디움',
          'imageUrl': 'https://example.com/backpack.png',
          'category': '백팩',
          'skuId': 1,
          'color': '블랙',
          'size': '미디움',
          'currentStoreInStock': false,
          'otherStoreInStock': true,
          'restockPlanned': false,
          'actionButtonLabel': 'Last Intent 시작',
          'savedAt': '2026-08-16T16:54:29',
        },
      ],
    );
    final RealSegueRepository repository = RealSegueRepository(
      apiClient: apiClient,
    );

    final List<CartItem> items = await repository.fetchCart(
      customerId: 1,
      storeId: 1,
    );

    expect(apiClient.lastGetPath, '/api/cart');
    expect(apiClient.lastGetQueryParameters, <String, Object?>{
      'customerId': 1,
      'storeId': 1,
    });
    expect(items.single.skuId, 1);
    expect(items.single.inventory.otherStoreInStock, isTrue);
  });

  test(
    'HTTP client converts slow backend responses into retryable timeout errors',
    () async {
      final HttpSegueApiClient apiClient = HttpSegueApiClient(
        httpClient: MockClient((http.Request request) async {
          await Future<void>.delayed(const Duration(milliseconds: 30));
          return http.Response('{}', 200);
        }),
        timeout: const Duration(milliseconds: 1),
      );

      await expectLater(
        apiClient.getJson('/api/cart'),
        throwsA(
          isA<ApiException>()
              .having((ApiException error) => error.statusCode, 'statusCode', 0)
              .having(
                (ApiException error) => error.code,
                'code',
                'REQUEST_TIMEOUT',
              ),
        ),
      );
    },
  );
}

class _RecordingApiClient implements SegueApiClient {
  _RecordingApiClient({this.getResponse, this.postResponse});

  final Object? getResponse;
  final Object? postResponse;
  String? lastGetPath;
  Map<String, Object?>? lastGetQueryParameters;
  String? lastPostPath;
  JsonMap? lastPostBody;

  @override
  Future<Object?> getJson(
    String path, {
    Map<String, Object?> queryParameters = const <String, Object?>{},
  }) async {
    lastGetPath = path;
    lastGetQueryParameters = Map<String, Object?>.of(queryParameters);
    return getResponse;
  }

  @override
  Future<Object?> postJson(
    String path, {
    JsonMap body = const <String, Object?>{},
  }) async {
    lastPostPath = path;
    lastPostBody = Map<String, Object?>.of(body);
    return postResponse;
  }

  @override
  Future<Object?> patchJson(
    String path, {
    JsonMap body = const <String, Object?>{},
  }) {
    throw UnimplementedError();
  }
}
