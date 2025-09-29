-- migrations/006_add_role_moderator.sql
DO $block$
BEGIN
  IF EXISTS (
    SELECT 1 FROM public.schema_migrations
    WHERE filename = '006_add_role_moderator.sql'
  ) THEN
    RAISE NOTICE '006_add_role_moderator.sql already applied, skipping';
    RETURN;
  END IF;

  -- role enum에 moderator 추가 (이미 있으면 스킵)
  ALTER TYPE app.role ADD VALUE IF NOT EXISTS 'moderator';

  INSERT INTO public.schema_migrations(filename)
  VALUES ('006_add_role_moderator.sql');
END
$block$;