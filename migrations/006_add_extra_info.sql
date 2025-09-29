-- migrations/006_add_extra_info.sql
DO $block$
BEGIN
  IF EXISTS (SELECT 1 FROM public.schema_migrations WHERE filename='006_add_extra_info.sql') THEN
    RAISE NOTICE '006_add_extra_info.sql already applied, skipping';
    RETURN;
  END IF;

  -- 대상 테이블 목록
  PERFORM 1;

  -- users
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='app' AND table_name='users' AND column_name='extra_info'
  ) THEN
    ALTER TABLE app.users ADD COLUMN extra_info JSONB DEFAULT '{}'::jsonb NOT NULL;
  END IF;

  -- species
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='app' AND table_name='species' AND column_name='extra_info'
  ) THEN
    ALTER TABLE app.species ADD COLUMN extra_info JSONB DEFAULT '{}'::jsonb NOT NULL;
  END IF;

  -- media
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='app' AND table_name='media' AND column_name='extra_info'
  ) THEN
    ALTER TABLE app.media ADD COLUMN extra_info JSONB DEFAULT '{}'::jsonb NOT NULL;
  END IF;

  -- sightings
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='app' AND table_name='sightings' AND column_name='extra_info'
  ) THEN
    ALTER TABLE app.sightings ADD COLUMN extra_info JSONB DEFAULT '{}'::jsonb NOT NULL;
  END IF;

  -- ai_detections
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='app' AND table_name='ai_detections' AND column_name='extra_info'
  ) THEN
    ALTER TABLE app.ai_detections ADD COLUMN extra_info JSONB DEFAULT '{}'::jsonb NOT NULL;
  END IF;

  -- comments
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='app' AND table_name='comments' AND column_name='extra_info'
  ) THEN
    ALTER TABLE app.comments ADD COLUMN extra_info JSONB DEFAULT '{}'::jsonb NOT NULL;
  END IF;

  -- likes
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='app' AND table_name='likes' AND column_name='extra_info'
  ) THEN
    ALTER TABLE app.likes ADD COLUMN extra_info JSONB DEFAULT '{}'::jsonb NOT NULL;
  END IF;

  -- reports
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='app' AND table_name='reports' AND column_name='extra_info'
  ) THEN
    ALTER TABLE app.reports ADD COLUMN extra_info JSONB DEFAULT '{}'::jsonb NOT NULL;
  END IF;

  INSERT INTO public.schema_migrations(filename) VALUES ('006_add_extra_info.sql');
END
$block$;