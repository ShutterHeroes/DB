# docker 연습 프로젝트
docker 연습을 위한 프로젝트입니다

## Database Migrations

본 레포의 `migrations/` 폴더에는 DB 스키마 변경 이력이 **파일명 오름차순(000 → 001 → …)** 으로 정렬되어 있습니다.  
각 파일은 내부에서 `public.schema_migrations`를 이용해 **멱등(idempotent)** 하게 동작합니다.

### 실행 전제
- Docker로 PostGIS 컨테이너가 떠 있고, 다음으로 접속 가능해야 합니다.
  - HOST: 127.0.0.1
  - PORT: 5433
  - USER: postgres
  - DB  : mydatabase
  - PASS: 8033 (변경 시 스크립트/환경변수 수정)

### 실행 방법
**Windows(PowerShell)**:
```powershell
./scripts/migrate.ps1