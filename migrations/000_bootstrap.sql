-- migrations/000_setup.sql
DO $block$
BEGIN
  -- 마이그레이션 기록 테이블
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relname = 'schema_migrations' AND n.nspname = 'public'
  ) THEN
    CREATE TABLE public.schema_migrations (
      filename   text PRIMARY KEY,
      applied_at timestamptz NOT NULL DEFAULT now()
    );
  END IF;

  -- 이미 적용되었으면 스킵
  IF EXISTS (SELECT 1 FROM public.schema_migrations WHERE filename = '000_setup.sql') THEN
    RAISE NOTICE '000_setup.sql already applied, skipping';
    RETURN;
  END IF;

  -- 스키마
  EXECUTE 'CREATE SCHEMA IF NOT EXISTS app';

  -- 확장
  EXECUTE 'CREATE EXTENSION IF NOT EXISTS postgis';
  EXECUTE 'CREATE EXTENSION IF NOT EXISTS pgcrypto';

  -- 공통 함수: updated_at 자동 갱신
  EXECUTE $sql$
    CREATE OR REPLACE FUNCTION app.touch_updated_at()
    RETURNS trigger LANGUAGE plpgsql AS $f$
    BEGIN
      NEW.updated_at := now();
      RETURN NEW;
    END
    $f$;
  $sql$;

  -- ENUM 타입들
  IF NOT EXISTS (
    SELECT 1 FROM pg_type t JOIN pg_namespace n ON n.oid=t.typnamespace
    WHERE t.typname='role' AND n.nspname='app'
  ) THEN
    EXECUTE 'CREATE TYPE app.role AS ENUM (''user'',''admin'')';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_type t JOIN pg_namespace n ON n.oid=t.typnamespace
    WHERE t.typname='species_status' AND n.nspname='app'
  ) THEN
    EXECUTE 'CREATE TYPE app.species_status AS ENUM (''general'',''endangered'',''natural_monument'')';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_type t JOIN pg_namespace n ON n.oid=t.typnamespace
    WHERE t.typname='visibility' AND n.nspname='app'
  ) THEN
    EXECUTE 'CREATE TYPE app.visibility AS ENUM (''public'',''private'')';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_type t JOIN pg_namespace n ON n.oid=t.typnamespace
    WHERE t.typname='detected_by' AND n.nspname='app'
  ) THEN
    EXECUTE 'CREATE TYPE app.detected_by AS ENUM (''ai'',''user'')';
  END IF;

  -- 적용 기록
  INSERT INTO public.schema_migrations(filename) VALUES ('000_setup.sql');
END
$block$;