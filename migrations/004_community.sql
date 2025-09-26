-- migrations/004_community.sql
DO $block$
BEGIN
  IF EXISTS (SELECT 1 FROM public.schema_migrations WHERE filename='004_community.sql') THEN
    RAISE NOTICE '004_community.sql already applied, skipping';
    RETURN;
  END IF;

  -- 댓글
  CREATE TABLE IF NOT EXISTS app.comments (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    sighting_id uuid NOT NULL REFERENCES app.sightings(id) ON DELETE CASCADE,
    user_id     uuid NOT NULL REFERENCES app.users(id) ON DELETE CASCADE,
    body        text NOT NULL,
    created_at  timestamptz NOT NULL DEFAULT now(),
    updated_at  timestamptz
  );
  CREATE INDEX IF NOT EXISTS idx_comments_sighting ON app.comments(sighting_id);
  DROP TRIGGER IF EXISTS trg_comments_touch ON app.comments;
  CREATE TRIGGER trg_comments_touch
    BEFORE UPDATE ON app.comments
    FOR EACH ROW EXECUTE FUNCTION app.touch_updated_at();

  -- 좋아요
  CREATE TABLE IF NOT EXISTS app.likes (
    sighting_id uuid NOT NULL REFERENCES app.sightings(id) ON DELETE CASCADE,
    user_id     uuid NOT NULL REFERENCES app.users(id) ON DELETE CASCADE,
    created_at  timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (sighting_id, user_id)
  );

  -- 신고(부적절/오탐 등)
  CREATE TABLE IF NOT EXISTS app.reports (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    sighting_id uuid NOT NULL REFERENCES app.sightings(id) ON DELETE CASCADE,
    reporter_id uuid NOT NULL REFERENCES app.users(id) ON DELETE CASCADE,
    reason      text NOT NULL,
    created_at  timestamptz NOT NULL DEFAULT now(),
    resolved    boolean NOT NULL DEFAULT false,
    resolved_at timestamptz
  );
  CREATE INDEX IF NOT EXISTS idx_reports_sighting ON app.reports(sighting_id);

  INSERT INTO public.schema_migrations(filename) VALUES ('004_community.sql');
END
$block$;