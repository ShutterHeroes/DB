

DB 개발 환경 (PostgreSQL + PostGIS)

이 저장소는 Docker Compose로 PostgreSQL 15 + PostGIS 3.4 서버를 띄우고,
migrations/ 디렉토리의 SQL을 자동으로 순서대로 적용합니다.
개발 환경에서는 1xx 시드(더미데이터)도 자동 주입됩니다.

요구사항

Docker Desktop (Mac/Windows) 또는 Docker Engine (Linux)

Git

디렉토리 구조
.
├─ docker-compose.yml
├─ migrations/            # 마이그레이션 SQL (0xx: 스키마, 1xx: 시드)
│   ├─ 000_bootstrap.sql
│   ├─ 001_....sql
│   ├─ ...
│   └─ 100_seed_dev.sql   # 개발용 더미데이터 (::float8 반영)
├─ scripts/
│   └─ migrate.sh         # 마이그레이션 실행 스크립트(컨테이너 내부에서 실행)
└─ postgres_data/         # DB 데이터 디렉토리(바인드 마운트; Git에 올리지 않음)


중요: postgres_data/ 폴더는 로컬 데이터가 저장되는 곳입니다. 반드시 Git에서 제외하세요.





# 2) 컨테이너 부팅 (DB + migrator)
docker compose up -d

# 3) 마이그레이션/시드 로그 확인
docker compose logs migrator --no-log-prefix


정상 로그 예:

== Waiting for PostgreSQL at db:5432 ==
== DB is ready, starting migrations ==
== Running schema migrations ==
-> Applying 000_bootstrap.sql
-> Applying 001_...
...
== Running seed data ==
-> Applying 100_seed_dev.sql
== Migration complete ==

검증(Verification)

DB 클라이언트나 VSCode 확장에서 다음 쿼리를 실행합니다.

-- PostGIS / 검색경로
SELECT extname FROM pg_extension WHERE extname='postgis';
SHOW search_path;

-- 마이그레이션 기록
SELECT filename, applied_at
FROM public.schema_migrations
ORDER BY applied_at DESC;

-- 핵심 테이블 카운트
SELECT 'users' t, COUNT(*) FROM app.users
UNION ALL SELECT 'species', COUNT(*) FROM app.species
UNION ALL SELECT 'media', COUNT(*) FROM app.media
UNION ALL SELECT 'sightings', COUNT(*) FROM app.sightings
UNION ALL SELECT 'comments', COUNT(*) FROM app.comments
UNION ALL SELECT 'likes', COUNT(*) FROM app.likes
UNION ALL SELECT 'reports', COUNT(* ) FROM app.reports;

시드(더미데이터) 켜고/끄기

기본: RUN_SEED: "true" (개발환경)

운영처럼 시드를 끄고 싶다면 docker-compose.yml 의 migrator.environment.RUN_SEED 를 "false" 로 변경 후 재시작:

docker compose down
docker compose up -d


또는 일회성 실행:

docker compose run --rm -e RUN_SEED=false migrator

마이그레이션 파일 작성 규칙

파일명으로 실행 순서가 결정됩니다.

0xx_*.sql : 스키마/함수/뷰/제약 추가 등

1xx_*.sql : 시드(더미데이터)

멱등성을 지켜주세요.

스키마 변경: IF NOT EXISTS, 존재 여부 체크 후 실행

시드: IF NOT FOUND / WHERE NOT EXISTS 패턴 사용

마지막에 꼭 기록:

INSERT INTO public.schema_migrations(filename) VALUES ('<파일명>');


PostGIS 좌표 리터럴은 타입 오류를 피하기 위해 반드시 ::float8 캐스팅:

ST_SetSRID(ST_MakePoint(127.0::float8, 37.5::float8), 4326)

자주 쓰는 명령
# 상태 보기
docker compose ps

# 로그 보기
docker compose logs db --no-log-prefix
docker compose logs migrator --no-log-prefix

# 컨테이너 종료/삭제
docker compose down

# 완전 초기화(데이터 삭제 포함)
docker compose down
rm -rf postgres_data
docker compose up -d

문제 해결 (Troubleshooting)
1) migrator 로그에 파일 적용 로그가 안 보임

migrations/ 폴더가 정확한 철자인지 확인 (오탈자: immigration/imigration 등)

실제로 migrations/ 폴더 안에 0xx/1xx 파일이 존재하는지 확인

docker compose exec migrator sh -lc 'ls -la /migrations' 로 컨테이너 내부에서 보이는지 확인

2) Connection refused / DB 접속 불가

DB가 기동되기 전에 붙는 경우 → scripts/migrate.sh가 DB 준비까지 대기하도록 구현되어 있습니다.
그래도 발생하면 docker compose logs db --no-log-prefix 로 healthcheck 실패 원인을 확인하세요.

포트 충돌이 있는지 확인(호스트 5433 사용 중인지).

3) st_makepoint(numeric, numeric) does not exist

좌표 리터럴에 ::float8 캐스팅이 빠진 경우입니다.
ST_MakePoint(경도::float8, 위도::float8)로 수정하세요.

4) ON CONFLICT ... matching constraint not found

스키마에 해당 UNIQUE 제약이 없을 때 발생합니다.
스키마 변경을 피하려면 seed에서 WHERE NOT EXISTS 패턴을 쓰세요.

백엔드 삽입 쿼리 가이드 (좌표 타입)

운영 코드에서는 파라미터 바인딩과 함께 아래 패턴을 권장합니다.

INSERT INTO app.sightings (
  user_id, species_id, title, description, occurred_at,
  detected_by, visibility, geom
) VALUES (
  $1, $2, $3, $4, $5,
  $6, $7,
  ST_SetSRID(ST_MakePoint($8::float8, $9::float8), 4326)
);


또는 DB 래퍼 함수:

SELECT app.create_sighting($1,$2,$3,$4,$5,$6,$7,$8,$9);

개발 팁

Windows에서는 스크립트/SQL 파일의 개행을 LF(Unix) 로 맞추는 것을 권장합니다.
(VSCode 오른쪽 하단에서 CRLF → LF)

VSCode PostgreSQL 확장으로 바로 쿼리 실행/테이블 구조 확인 가능.

유지보수 워크플로우 제안

스키마 변경은 새 0xx 파일 추가로만 수행 (기존 파일 수정 지양)

시드는 1xx 파일에 추가

PR에서 migrator 로그 캡처(적용 결과) 같이 제출

스테이징에서 먼저 확인 후 메인 브랜치 병합