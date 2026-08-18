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
    'real repository executes the card request and fetches the saved mobile result',
    () async {
      final _RecordingApiClient apiClient = _RecordingApiClient(
        postResponse: <String, Object?>{
          'consultationResultId': 5,
          'completionMessage': '요청이 접수되었습니다. CA가 실제 재고를 확인합니다',
        },
        getResponse: <Object?>[_consultationResultJson()],
      );
      final RealSegueRepository repository = RealSegueRepository(
        apiClient: apiClient,
      );

      final ExecuteConsultationResponse executeResponse = await repository
          .executeConsultation(
            ExecuteConsultationRequest.fromDecisionResult(
              customerId: 1,
              skuId: 1,
              decisionResult: DecisionResult.fromJson(_decisionResultJson()),
            ),
          );

      expect(apiClient.lastPostPath, '/api/consultations/execute');
      expect(apiClient.lastPostBody, <String, Object?>{
        'customerId': 1,
        'skuId': 1,
        'resultType': 'EXACT_PRODUCT',
        'actionType': 'OTHER_STORE_CHECK_REQUEST',
        'recommendedSkuId': null,
        'pathDescription': '강남 신세계점 재고 확인',
        'coreConditionsSummary': '로고가 정면 중앙에 오는 각진 실루엣을 중요하게 보고 계셨습니다.',
      });
      expect(executeResponse.consultationResultId, 5);

      final List<ConsultationResult> results = await repository
          .fetchConsultationResults(1);

      expect(apiClient.lastGetPath, '/api/consultations/customers/1');
      expect(results.single.id, executeResponse.consultationResultId);
      expect(results.single.recommendedPath, '강남 신세계점 재고 확인');
      expect(
        results.single.coreConditions,
        '로고가 정면 중앙에 오는 각진 실루엣을 중요하게 보고 계셨습니다.',
      );
      expect(results.single.executionStatus, ExecutionStatus.requested);
    },
  );

  test(
    'real repository posts staff utterance to the AI intent endpoint',
    () async {
      final _RecordingApiClient apiClient = _RecordingApiClient(
        postResponse: _structureIntentResponseJson(needsFollowUp: true),
      );
      final RealSegueRepository repository = RealSegueRepository(
        apiClient: apiClient,
      );

      final StructureIntentResponse response = await repository.structureIntent(
        const StructureIntentRequest(
          storeId: 1,
          skuId: 1,
          utterance: '로고 위치와 각진 형태가 좋아요',
        ),
      );

      expect(apiClient.lastPostPath, '/api/consultations/intent');
      expect(apiClient.lastPostBody, <String, Object?>{
        'storeId': 1,
        'skuId': 1,
        'utterance': '로고 위치와 각진 형태가 좋아요',
      });
      expect(response.needsFollowUp, isTrue);
      expect(response.structuredIntent.essentialConditions, <String, String>{
        'logoPosition': '정면중앙',
        'silhouette': '각진',
      });
    },
  );

  test(
    'real repository posts follow-up question and answer payloads',
    () async {
      final StructuredIntent currentIntent = StructuredIntent.fromJson(
        asJsonMap(_structuredIntentJson(needsFollowUp: true)),
      );
      final _RecordingApiClient questionClient = _RecordingApiClient(
        postResponse: <String, Object?>{'question': '오늘 바로 구매를 원하시나요?'},
      );
      final RealSegueRepository questionRepository = RealSegueRepository(
        apiClient: questionClient,
      );

      final FollowUpQuestion question = await questionRepository
          .requestFollowUpQuestion(
            FollowUpQuestionRequest(
              utterance: '비슷한 제품도 괜찮아요',
              currentIntent: currentIntent,
            ),
          );

      expect(
        questionClient.lastPostPath,
        '/api/consultations/followup-question',
      );
      expect(questionClient.lastPostBody?['utterance'], '비슷한 제품도 괜찮아요');
      expect(
        questionClient.lastPostBody?['currentIntent'],
        currentIntent.toJson(),
      );
      expect(question.question, '오늘 바로 구매를 원하시나요?');

      final _RecordingApiClient answerClient = _RecordingApiClient(
        postResponse: _structureIntentResponseJson(needsFollowUp: false),
      );
      final RealSegueRepository answerRepository = RealSegueRepository(
        apiClient: answerClient,
      );

      final StructureIntentResponse answerResponse = await answerRepository
          .submitFollowUpAnswer(
            const FollowUpAnswerRequest(
              utterance: '비슷한 제품도 괜찮아요',
              followUpQuestion: '오늘 바로 구매를 원하시나요?',
              followUpAnswer: '오늘 살 필요는 없어요',
            ),
          );

      expect(answerClient.lastPostPath, '/api/consultations/followup-answer');
      expect(answerClient.lastPostBody, <String, Object?>{
        'utterance': '비슷한 제품도 괜찮아요',
        'followUpQuestion': '오늘 바로 구매를 원하시나요?',
        'followUpAnswer': '오늘 살 필요는 없어요',
      });
      expect(answerResponse.needsFollowUp, isFalse);
    },
  );

  test(
    'real repository sends the confirmed StructuredIntent to decide',
    () async {
      final StructuredIntent confirmedIntent = StructuredIntent.fromJson(
        asJsonMap(_structuredIntentJson()),
      ).copyWith(purchaseUrgency: PurchaseUrgency.today);
      final _RecordingApiClient apiClient = _RecordingApiClient(
        postResponse: _decisionResultJson(),
      );
      final RealSegueRepository repository = RealSegueRepository(
        apiClient: apiClient,
      );

      final DecisionResult result = await repository.decide(
        DecisionRequest(
          storeId: 1,
          skuId: 1,
          structuredIntent: confirmedIntent,
        ),
      );

      expect(apiClient.lastPostPath, '/api/consultations/decide');
      expect(apiClient.lastPostBody, <String, Object?>{
        'storeId': 1,
        'skuId': 1,
        'structuredIntent': confirmedIntent.toJson(),
      });
      expect(result.resultType, DecisionResultType.exactProduct);
      expect(result.actionButtonLabel, '타 매장 확인 요청');
    },
  );

  test(
    'real AI/engine schema mismatches become retryable API errors',
    () async {
      final _RecordingApiClient missingKeyClient = _RecordingApiClient(
        postResponse: <String, Object?>{'needsFollowUp': false},
      );
      final RealSegueRepository repository = RealSegueRepository(
        apiClient: missingKeyClient,
      );

      await expectLater(
        repository.structureIntent(
          const StructureIntentRequest(storeId: 1, skuId: 1, utterance: '테스트'),
        ),
        throwsA(
          isA<ApiException>().having(
            (ApiException error) => error.code,
            'code',
            'JSON_SCHEMA_MISMATCH',
          ),
        ),
      );

      final JsonMap invalidVocabularyResponse = _structureIntentResponseJson();
      final JsonMap intent = asJsonMap(
        invalidVocabularyResponse['structuredIntent'],
      );
      intent['essentialConditions'] = <String, Object?>{'glossLevel': '보통'};
      final _RecordingApiClient invalidVocabularyClient = _RecordingApiClient(
        postResponse: invalidVocabularyResponse,
      );
      final RealSegueRepository invalidVocabularyRepository =
          RealSegueRepository(apiClient: invalidVocabularyClient);

      await expectLater(
        invalidVocabularyRepository.structureIntent(
          const StructureIntentRequest(storeId: 1, skuId: 1, utterance: '테스트'),
        ),
        throwsA(
          isA<ApiException>().having(
            (ApiException error) => error.code,
            'code',
            'JSON_SCHEMA_MISMATCH',
          ),
        ),
      );
    },
  );

  test(
    'real consultation result schema mismatches become retryable API errors',
    () async {
      final _RecordingApiClient badExecuteClient = _RecordingApiClient(
        postResponse: <String, Object?>{'completionMessage': '접수'},
      );
      final RealSegueRepository badExecuteRepository = RealSegueRepository(
        apiClient: badExecuteClient,
      );

      await expectLater(
        badExecuteRepository.executeConsultation(
          ExecuteConsultationRequest.fromDecisionResult(
            customerId: 1,
            skuId: 1,
            decisionResult: DecisionResult.fromJson(_decisionResultJson()),
          ),
        ),
        throwsA(
          isA<ApiException>().having(
            (ApiException error) => error.code,
            'code',
            'JSON_SCHEMA_MISMATCH',
          ),
        ),
      );

      final JsonMap invalidResult = _consultationResultJson()
        ..remove('executionStatus');
      final _RecordingApiClient badResultClient = _RecordingApiClient(
        getResponse: <Object?>[invalidResult],
      );
      final RealSegueRepository badResultRepository = RealSegueRepository(
        apiClient: badResultClient,
      );

      await expectLater(
        badResultRepository.fetchConsultationResults(1),
        throwsA(
          isA<ApiException>().having(
            (ApiException error) => error.code,
            'code',
            'JSON_SCHEMA_MISMATCH',
          ),
        ),
      );
    },
  );

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

JsonMap _structureIntentResponseJson({bool needsFollowUp = false}) {
  return <String, Object?>{
    'structuredIntent': _structuredIntentJson(needsFollowUp: needsFollowUp),
    'needsFollowUp': needsFollowUp,
  };
}

JsonMap _structuredIntentJson({bool needsFollowUp = false}) {
  return <String, Object?>{
    'purpose': '',
    'essentialConditions': <String, Object?>{
      'logoPosition': '정면중앙',
      'silhouette': '각진',
    },
    'preferredConditions': <String, Object?>{},
    'negotiableConditions': <String, Object?>{},
    'purchaseUrgency': 'FLEXIBLE',
    'physicalCheckAttributes': <String>['logoPosition'],
    'canWait': true,
    'canVisitOtherStore': true,
    'needsFollowUp': needsFollowUp,
    'followUpReason': needsFollowUp ? '구매 시급성 확인 필요' : '',
  };
}

JsonMap _decisionResultJson() {
  return <String, Object?>{
    'resultType': 'EXACT_PRODUCT',
    'coreConditions': '로고가 정면 중앙에 오는 각진 실루엣을 중요하게 보고 계셨습니다.',
    'nextAction': '강남 신세계점 재고를 확인해 안내해 드릴 수 있습니다.',
    'reason': '언급된 로고 위치와 실루엣이 원제품의 특징과 일치합니다.',
    'difference': '동일 제품을 타 매장에서 확보하는 경로를 우선 제안드립니다.',
    'recommendedProduct': null,
    'pathDescription': '강남 신세계점 재고 확인',
    'actionType': 'OTHER_STORE_CHECK_REQUEST',
    'actionButtonLabel': '타 매장 확인 요청',
  };
}

JsonMap _consultationResultJson() {
  return <String, Object?>{
    'id': 5,
    'skuId': 1,
    'productName': 'MCM 백팩 미디움',
    'imageUrl': 'https://example.com/mcm-backpack.png',
    'resultType': 'EXACT_PRODUCT',
    'recommendedPath': '강남 신세계점 재고 확인',
    'coreConditions': '로고가 정면 중앙에 오는 각진 실루엣을 중요하게 보고 계셨습니다.',
    'consultedAt': '2026-08-16T15:20:00',
    'executionStatus': 'REQUESTED',
    'executionNote': null,
    'executionUpdatedAt': '2026-08-16T15:20:00',
  };
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
