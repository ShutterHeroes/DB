-- migrations/000_patch_search_path.sql
DO $block$
BEGIN
  -- 이미 적용됐으면 스킵
  IF EXISTS (SELECT 1 FROM public.schema_migrations WHERE filename='000_patch_search_path.sql') THEN
    RAISE NOTICE '000_patch_search_path.sql already applied, skipping';
    RETURN;
  END IF;

  -- DB 기본 search_path을 app, public으로 설정
  -- ▶ 앞으로 모든 세션에 기본 적용됨
  PERFORM current_database();  -- dummy to ensure inside a DO block
  EXECUTE 'ALTER DATABASE mydatabase SET search_path = app, public';

  -- (선택) 현재 세션에도 즉시 반영하고 싶으면 아래 한 줄을 켜세요.
  -- EXECUTE ''SET search_path TO app, public'';

  INSERT INTO public.schema_migrations(filename) VALUES ('000_patch_search_path.sql');
END
$block$;