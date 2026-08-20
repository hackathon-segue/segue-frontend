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

  test('real repository posts customer login credentials', () async {
    final _RecordingApiClient apiClient = _RecordingApiClient(
      postResponse: <String, Object?>{
        'customerId': 1,
        'name': '김세계',
        'email': 'segye@example.com',
        'phone': '010-1234-5678',
        'hasConsented': true,
      },
    );
    final RealSegueRepository repository = RealSegueRepository(
      apiClient: apiClient,
    );

    final Customer customer = await repository.loginCustomer(
      email: 'segye@example.com',
      password: 'password123',
    );

    expect(apiClient.lastPostPath, '/api/customers/login');
    expect(apiClient.lastPostBody, <String, Object?>{
      'email': 'segye@example.com',
      'password': 'password123',
    });
    expect(customer.id, 1);
    expect(customer.email, 'segye@example.com');
    expect(customer.phoneNumber, '010-1234-5678');
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
    'real repository fetches customer mobile products from /api/products',
    () async {
      final _RecordingApiClient apiClient = _RecordingApiClient(
        getResponse: <String, Object?>{
          'products': <Object?>[
            <String, Object?>{
              'productId': 6,
              'productName': 'Diamond 3D 카프스킨 숄더백',
              'imageUrl': '/images/products/diamond.png',
              'category': '가방',
              'collection': '신상품',
              'price': 2050000,
              'material': '스페니시 레더',
              'dimensions': 'W 24 x H 14 x D 7 cm',
              'origin': 'Made in Italy',
              'season': '2026 AW',
              'skus': <Object?>[
                <String, Object?>{
                  'skuId': 14,
                  'color': '오렌지',
                  'size': '스몰',
                  'material': '스페니시 레더',
                  'storageStructure': '내부 포켓 2개',
                  'wearStyle': '숄더',
                  'laptopCompatible': false,
                  'sizeGrade': '스몰',
                },
              ],
            },
          ],
        },
      );
      final RealSegueRepository repository = RealSegueRepository(
        apiClient: apiClient,
      );

      final List<MobileProduct> products = await repository
          .fetchMobileProducts();

      expect(apiClient.lastGetPath, '/api/products');
      expect(products.single.id, 6);
      expect(products.single.name, 'Diamond 3D 카프스킨 숄더백');
      expect(products.single.imageUrl, '/images/products/diamond.png');
      expect(products.single.collection, '신상품');
      expect(products.single.price, 2050000);
      expect(products.single.dimensions, 'W 24 x H 14 x D 7 cm');
      expect(products.single.origin, 'Made in Italy');
      expect(products.single.season, '2026 AW');
      expect(products.single.options.single.skuId, 14);
      expect(products.single.options.single.material, '스페니시 레더');
      expect(products.single.options.single.storageStructure, '내부 포켓 2개');
      expect(products.single.options.single.wearStyle, '숄더');
      expect(products.single.options.single.laptopCompatible, isFalse);
      expect(products.single.material, '스페니시 레더');
    },
  );

  test('real repository accepts backend product detail alias fields', () async {
    final _RecordingApiClient apiClient = _RecordingApiClient(
      getResponse: <String, Object?>{
        'productList': <Object?>[
          <String, Object?>{
            'id': 77,
            'name': '서버 별칭 토트',
            'image_url': '/images/products/alias.png',
            'category_name': '가방',
            'unit_price': 1090000,
            'season_name': '2026 AW',
            'skuList': <Object?>[
              <String, Object?>{
                'id': 7701,
                'color_name': '코냑',
                'size_name': '미디움',
                'weight_grams': 620,
                'storage_structure': '내부 포켓 2개',
                'wear_style': '토트',
                'laptop_compatible': false,
                'productAttribute': <String, Object?>{
                  'material': '비세토스 캔버스',
                  'color_family': '브라운',
                  'color_tone': '웜',
                  'size_grade': '미디움',
                },
              },
            ],
          },
        ],
      },
    );
    final RealSegueRepository repository = RealSegueRepository(
      apiClient: apiClient,
    );

    final List<MobileProduct> products = await repository.fetchMobileProducts();
    final MobileSkuOption sku = products.single.options.single;

    expect(products.single.id, 77);
    expect(products.single.name, '서버 별칭 토트');
    expect(products.single.imageUrl, '/images/products/alias.png');
    expect(products.single.price, 1090000);
    expect(sku.skuId, 7701);
    expect(sku.color, '코냑');
    expect(sku.size, '미디움');
    expect(sku.material, '비세토스 캔버스');
    expect(sku.weightGrams, 620);
    expect(sku.storageStructure, '내부 포켓 2개');
    expect(sku.wearStyle, '토트');
    expect(sku.laptopCompatible, isFalse);
    expect(sku.colorFamily, '브라운');
    expect(sku.colorTone, '웜');
    expect(sku.sizeGrade, '미디움');
  });

  test(
    'real repository hydrates summary products from product detail endpoints',
    () async {
      final _RecordingApiClient apiClient = _RecordingApiClient(
        getResponsesByPath: <String, Object?>{
          '/api/products': <Object?>[
            <String, Object?>{
              'id': 3,
              'name': 'M New Liz 비세토스 쇼퍼',
              'imageUrl': '/images/products/bag3.png',
              'category': '쇼퍼백',
            },
          ],
          '/api/products/3': <String, Object?>{
            'id': 3,
            'name': 'M New Liz 비세토스 쇼퍼',
            'imageUrl': '/images/products/bag3.png',
            'category': '쇼퍼백',
            'price': 1090000,
            'options': <Object?>[
              <String, Object?>{
                'skuId': 3,
                'color': '꼬냑',
                'size': 'M',
                'material': '비세토스 모노그램 캔버스 + 나파 가죽',
                'weightGrams': 520,
                'storageStructure': '오픈탑 + 내부 지퍼 포켓',
                'wearStyle': '쇼퍼',
                'laptopCompatible': true,
              },
            ],
          },
        },
      );
      final RealSegueRepository repository = RealSegueRepository(
        apiClient: apiClient,
      );

      final MobileProduct product =
          (await repository.fetchMobileProducts()).single;

      expect(apiClient.getPaths, <String>['/api/products', '/api/products/3']);
      expect(product.id, 3);
      expect(product.price, 1090000);
      expect(product.options.single.color, '꼬냑');
      expect(product.options.single.size, 'M');
      expect(product.options.single.material, '비세토스 모노그램 캔버스 + 나파 가죽');
      expect(product.options.single.laptopCompatible, isTrue);
    },
  );

  test(
    'real repository does not mix local catalog details into backend products',
    () async {
      final _RecordingApiClient apiClient = _RecordingApiClient(
        getResponse: <Object?>[
          <String, Object?>{
            'productId': 1,
            'productName': '백엔드 상품명',
            'category': '백엔드 카테고리',
            'skus': <Object?>[
              <String, Object?>{'skuId': 1, 'color': '블랙', 'size': '미디움'},
            ],
          },
        ],
      );
      final RealSegueRepository repository = RealSegueRepository(
        apiClient: apiClient,
      );

      final MobileProduct product =
          (await repository.fetchMobileProducts()).single;

      expect(product.name, '백엔드 상품명');
      expect(product.category, '백엔드 카테고리');
      expect(product.price, 0);
      expect(product.material, '');
      expect(product.dimensions, '');
      expect(product.origin, '');
      expect(product.season, '');
      expect(product.assetImagePath, isNull);
    },
  );

  test(
    'real repository does not infer missing display details from local names',
    () async {
      final _RecordingApiClient apiClient = _RecordingApiClient(
        getResponse: <Object?>[
          <String, Object?>{
            'productId': 501,
            'productName': '미니 Diamond 카프 레더 숄더백',
            'category': '가방',
            'imageUrl': '/images/products/mini-diamond.png',
          },
        ],
      );
      final RealSegueRepository repository = RealSegueRepository(
        apiClient: apiClient,
      );

      final MobileProduct product =
          (await repository.fetchMobileProducts()).single;

      expect(product.name, '미니 Diamond 카프 레더 숄더백');
      expect(product.price, 0);
      expect(product.material, '');
      expect(product.options, isEmpty);
      expect(product.imageUrl, '/images/products/mini-diamond.png');
    },
  );

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
    'structureIntent() tolerates AI response variance instead of failing '
    'the whole request — StructuredIntent.fromJson already defaults every '
    'missing/malformed/out-of-vocabulary field safely, so the extra '
    'pre-validation gate was only rejecting otherwise-usable AI output',
    () async {
      // Missing the whole `structuredIntent` key: still succeeds, backed by
      // StructuredIntent.empty()-equivalent defaults.
      final _RecordingApiClient missingKeyClient = _RecordingApiClient(
        postResponse: <String, Object?>{'needsFollowUp': false},
      );
      final RealSegueRepository repository = RealSegueRepository(
        apiClient: missingKeyClient,
      );

      final StructureIntentResponse missingKeyResponse = await repository
          .structureIntent(
            const StructureIntentRequest(
              storeId: 1,
              skuId: 1,
              utterance: '테스트',
            ),
          );
      expect(missingKeyResponse.structuredIntent.purpose, '');
      expect(missingKeyResponse.structuredIntent.essentialConditions, isEmpty);
      expect(
        missingKeyResponse.structuredIntent.purchaseUrgency,
        PurchaseUrgency.flexible,
      );

      // A condition value outside API.md's documented vocabulary: still
      // succeeds, keeping the AI's raw value rather than discarding the
      // whole structured intent over one unrecognized field.
      final JsonMap outOfVocabularyResponse = _structureIntentResponseJson();
      final JsonMap intent = asJsonMap(
        outOfVocabularyResponse['structuredIntent'],
      );
      intent['essentialConditions'] = <String, Object?>{'glossLevel': '보통'};
      final _RecordingApiClient outOfVocabularyClient = _RecordingApiClient(
        postResponse: outOfVocabularyResponse,
      );
      final RealSegueRepository outOfVocabularyRepository = RealSegueRepository(
        apiClient: outOfVocabularyClient,
      );

      final StructureIntentResponse outOfVocabularyResult =
          await outOfVocabularyRepository.structureIntent(
            const StructureIntentRequest(
              storeId: 1,
              skuId: 1,
              utterance: '테스트',
            ),
          );
      expect(
        outOfVocabularyResult.structuredIntent.essentialConditions,
        <String, String>{'glossLevel': '보통'},
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
  _RecordingApiClient({
    this.getResponse,
    this.postResponse,
    Map<String, Object?>? getResponsesByPath,
  }) : getResponsesByPath = getResponsesByPath ?? <String, Object?>{};

  final Object? getResponse;
  final Object? postResponse;
  final Map<String, Object?> getResponsesByPath;
  String? lastGetPath;
  Map<String, Object?>? lastGetQueryParameters;
  String? lastPostPath;
  JsonMap? lastPostBody;
  final List<String> getPaths = <String>[];

  @override
  Future<Object?> getJson(
    String path, {
    Map<String, Object?> queryParameters = const <String, Object?>{},
  }) async {
    lastGetPath = path;
    getPaths.add(path);
    lastGetQueryParameters = Map<String, Object?>.of(queryParameters);
    if (getResponsesByPath.containsKey(path)) {
      return getResponsesByPath[path];
    }
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
