# Segue — Frontend

**매장에 원하던 제품이 없을 때, 고객의 마지막 의도를 구조화해 다음 행동 하나를 제안하는 CA 상담 보조 서비스.**

성주재단 × MCM 해커톤 · Challenge 02 Interactive Retail

| | |
| --- | --- |
| 서비스 | **https://segue.asia** |
| 백엔드 | [segue-backend](https://github.com/hackathon-segue/segue-backend) |

---

## 두 개의 앱, 하나의 코드베이스

| | 사용자 | 진입 | 하는 일 |
| --- | --- | --- | --- |
| **고객 모바일** | 고객 | `/` | 제품 탐색 · 장바구니 · 상담 결과 확인 |
| **직원 태블릿** | Client Advisor | `/#/staff/home` | 고객 조회 · 재고 확인 · Last Intent 상담 |

기기도 화면 크기도 다르지만 Flutter Web 한 코드베이스다. 모델·API 계층은 공유하고 화면과 디자인 토큰만 분리해, 백엔드 응답 구조가 바뀌면 한 곳만 고치면 양쪽에 반영된다. 화면은 총 19개.

```
[고객 모바일]  제품 탐색 → 컬러·사이즈 선택 → 장바구니
                                  │
                                  ▼
[직원 태블릿]  고객 조회 → 데이터 이용 동의 → 장바구니·재고 확인
                                  │
                        "현재 매장 미보유" → Last Intent 시작
                                  │
               고객 발화 입력 → (필요 시 보충 질문 1회) → 조건 확인·수정
                                  │
                        Last Intent Card → 실행 요청
                                  │
                                  ▼
[고객 모바일]  SEGUE 내역에서 결과와 처리 상태 확인
```

결과 유형 네 가지(정확한 제품 확인 / 비교 체험 / 오늘 구매 가능 / 추가 상담)마다 카드와 실행 버튼이 다르다.

---

## 설계

**저장소 이중화 — 백엔드 없이 화면부터.** `SegueRepository` 인터페이스를 Mock/Real 두 구현으로 분리하고 `RepositoryScope` 가 실행 시점에 주입한다. 화면 코드는 어느 쪽인지 모른다. 백엔드 완성 전에 전체 플로우를 화면으로 검증했고, 지금도 백엔드 없이 UI 작업이 가능하다.

```
SegueRepository (abstract)
├── MockSegueRepository   고정 fixture
└── RealSegueRepository   실제 백엔드 호출
```

**응답 검증.** `200` 이어도 구조가 다를 수 있어 `decision_result_validator` · `structured_intent_vocabulary` 로 검증하고, 어긋나면 화면을 깨뜨리는 대신 "다시 확인이 필요합니다" 상태로 안내한다. 연동 중 이 검증이 백엔드 응답 형식 불일치를 먼저 잡아냈다.

**상태 관리는 직접.** 상태 관리 라이브러리 없이 `InheritedWidget` 기반 Scope 3개. 의존성은 `http` 와 `flutter_svg` 뿐이고, 로딩·성공·실패는 자체 `AsyncValue` 로 다룬다.

| Scope | 담당 |
| --- | --- |
| `RepositoryScope` | API 구현체 주입 |
| `StaffSessionScope` | 직원 세션 (조회한 고객, 선택한 매장) |
| `LastIntentSessionScope` | 상담 세션 — 미보유 제품이 여러 개면 **하나씩 순서대로** |

**API 주소는 빌드 시점 주입.** `String.fromEnvironment('API_BASE_URL')` 로 받아 코드에 박지 않는다. 기본값은 빈 문자열이고, 이때 모든 요청이 같은 오리진 상대 경로(`/api/...`, `/images/...`)로 만들어진다. 제품 이미지의 상대 경로도 같은 규칙으로 해석한다.

---

## 로컬 실행

**요구사항** — Flutter stable 3.38.x / Dart 3.10.x

```bash
flutter pub get

# 백엔드 연결
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080

# Mock 단독
flutter run -d chrome --dart-define=USE_MOCK_DATA=true
```

| 키 | 기본값 | 설명 |
| --- | --- | --- |
| `API_BASE_URL` | `` (빈 값) | 백엔드 주소. 비어 있으면 같은 오리진 상대 경로로 요청한다. 로컬에서 별도 포트의 백엔드에 붙을 때만 지정한다 |
| `APP_ENV` | `local` | 화면 하단 표시용 |
| `USE_MOCK_DATA` | `false` | `true` 면 Mock 저장소 |
| `STORE_ID` | `1` | 태블릿이 서 있는 매장 |
| `CUSTOMER_ID` | `1` | 개발용 기본 고객 |
| `API_TIMEOUT_SECONDS` | `10` | HTTP 타임아웃 |
| `APP_NAME` | `Segue` | 앱 표시 이름 |

> `--dart-define` 값은 `main.dart.js` 에 그대로 컴파일되어 브라우저에서 읽을 수 있다. **API 키·시크릿은 여기에 넣지 않는다.**

### 라우팅

`usePathUrlStrategy()` 를 쓰지 않아 웹에서는 해시 라우팅으로 동작한다. 주소를 직접 입력할 때는 `#` 이 필요하다.

```
https://segue.asia/              고객 모바일
https://segue.asia/#/staff/home  직원 태블릿
```

Last Intent 내부 단계(발화 입력 이후)는 `Navigator.push` 로 열리는 이름 없는 라우트라 주소로 직접 진입할 수 없다.

---

## 빌드 · 배포

배포 경로는 두 가지이고, 둘 다 **프론트와 API 를 같은 오리진에서 보이게** 한다. 오리진이 갈리면 CORS 와 혼합 콘텐츠 문제가 생기는데, 한 주소로 합치면 발생 여지 자체가 없다.

### 1. 백엔드 서버에 함께 배포 (운영: segue.asia)

빌드 결과물을 백엔드 서버의 정적 디렉터리에 올린다. 서버에 없는 경로는 `index.html` 로 폴백하므로 직접 진입·새로고침도 유지된다.

```bash
flutter build web \
  --dart-define=API_BASE_URL=https://segue.asia \
  --dart-define=APP_ENV=prod

scp -r build/web/* <계정>@<서버>:/var/www/segue/
```

> 재배포 후 **하드 리프레시**(`Cmd/Ctrl + Shift + R`) 필요. 서비스 워커가 이전 파일을 캐싱한다.

### 2. Vercel

`vercel.json` 과 빌드 스크립트가 저장소에 있어 GitHub 임포트만으로 Flutter Web 을 빌드한다. `build/web` 을 커밋할 필요가 없다.

- `scripts/vercel_install_flutter.sh` — Flutter stable 설치 후 `flutter pub get`
- `scripts/vercel_build_flutter_web.sh` — `flutter build web --release`
- `vercel.json` — `build/web` 서빙, `/api/*` 와 `/images/*` 를 백엔드로 rewrite, 나머지는 `index.html` 로 폴백

`API_BASE_URL` 을 비워 두는 것이 여기서 중요하다. 앱이 같은 오리진 상대 경로로 요청하면 Vercel 의 rewrite 가 백엔드로 넘겨 주므로, 백엔드 주소가 컴파일된 앱에 박히지 않는다.

---

## 구조

```
lib/
├── screens/        19개 화면 (고객 모바일 · 직원 태블릿)
├── widgets/        공통 UI — 카드 셸, 상태 뷰, 제품 이미지
├── repositories/   API 계층 — 인터페이스 + Mock/Real 구현
├── models/         백엔드 DTO 대응 모델
├── providers/      InheritedWidget 기반 세션·저장소 Scope
├── exceptions/     API 오류 타입
└── utils/          설계 토큰 · 라우트 · 응답 검증 · 어휘 정의
```

---

## 테스트 계정

비밀번호 둘 다 `segue1234`. 고객 모바일은 이메일 로그인, 직원 태블릿은 전화번호 조회.

| 이메일 | 전화번호 | 용도 |
| --- | --- | --- |
| `kim@segue.test` | `010-1234-5678` | 기본 시연 (동의 완료) |
| `lee@segue.test` | `010-9876-5432` | 동의 차단 흐름 |
