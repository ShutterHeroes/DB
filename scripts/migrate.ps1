# 실행:  PowerShell에서  ./scripts/migrate.ps1
# 필요 시 환경정보 수정
$PGHOST = "127.0.0.1"
$PGPORT = "5433"
$PGUSER = "postgres"
$PGDATABASE = "mydatabase"
$env:PGPASSWORD = "8033"   # 비번 노출이 싫으면 입력받게 바꾸세요

$psql = "psql -h $PGHOST -p $PGPORT -U $PGUSER -d $PGDATABASE -v ON_ERROR_STOP=1 -X -q"

Write-Host "== DB Migrations 시작 =="

# migrations/*.sql을 파일명 오름차순으로 실행
$files = Get-ChildItem -Path "migrations" -Filter "*.sql" | Sort-Object Name
foreach ($f in $files) {
  Write-Host ("-> 적용 중: {0}" -f $f.Name)
  $exit = cmd /c "$psql -f `"$($f.FullName)`""
  if ($LASTEXITCODE -ne 0) {
    Write-Host ("!! 실패: {0}" -f $f.Name) -ForegroundColor Red
    exit 1
  }
}

Write-Host "== 완료 =="
# 적용 내역 확인(선택)
cmd /c "$psql -c `"TABLE public.schema_migrations;`""