#!/usr/bin/env sh
set -e

# ---- wait for DB ---------------------------------------------------
echo "== Waiting for PostgreSQL at ${PGHOST:-db}:${PGPORT:-5432} =="
i=0
until psql -h "${PGHOST:-db}" -p "${PGPORT:-5432}" -U "${PGUSER:-postgres}" -d "${PGDATABASE:-mydatabase}" -X -q -c "SELECT 1;" >/dev/null 2>&1
do
  i=$((i+1))
  if [ $i -ge 60 ]; then
    echo "!! DB not ready after 60s, aborting"; exit 1
  fi
  sleep 1
done
echo "== DB is ready, starting migrations =="

# ---- run 0xx -------------------------------------------------------
echo "== Running schema migrations =="
found=0
for f in /migrations/0*.sql; do
  [ -e "$f" ] || continue
  found=1
  echo "-> Applying $(basename "$f")"
  psql -h "${PGHOST:-db}" -p "${PGPORT:-5432}" -U "${PGUSER:-postgres}" -d "${PGDATABASE:-mydatabase}" \
       -v ON_ERROR_STOP=1 -X -q -f "$f"
done
[ $found -eq 1 ] || echo "-- no 0xx files found --"

# ---- run 1xx (seed) ------------------------------------------------
if [ "${RUN_SEED}" = "true" ]; then
  echo "== Running seed data =="
  found_seed=0
  for f in /migrations/1*.sql; do
    [ -e "$f" ] || continue
    found_seed=1
    echo "-> Applying $(basename "$f")"
    psql -h "${PGHOST:-db}" -p "${PGPORT:-5432}" -U "${PGUSER:-postgres}" -d "${PGDATABASE:-mydatabase}" \
         -v ON_ERROR_STOP=1 -X -q -f "$f"
  done
  [ $found_seed -eq 1 ] || echo "-- no 1xx seed files found --"
fi

echo "== Migration complete =="
