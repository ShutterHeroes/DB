-- migrations/001_users.sql
DO $block$
BEGIN
  IF EXISTS (SELECT 1 FROM public.schema_migrations WHERE filename='001_users.sql') THEN
    RAISE NOTICE '001_users.sql already applied, skipping';
    RETURN;
  END IF;

  -- 사용자
  CREATE TABLE IF NOT EXISTS app.users (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    email         text UNIQUE NOT NULL,
    password_hash text,                        -- 외부 OAuth 쓰면 NULL 가능
    display_name  text NOT NULL,
    avatar_url    text,
    role          app.role NOT NULL DEFAULT 'user',
    created_at    timestamptz NOT NULL DEFAULT now(),
    updated_at    timestamptz,
    last_login_at timestamptz
  );

  -- updated_at 트리거
  DROP TRIGGER IF EXISTS trg_users_touch ON app.users;
  CREATE TRIGGER trg_users_touch
    BEFORE UPDATE ON app.users
    FOR EACH ROW EXECUTE FUNCTION app.touch_updated_at();

  INSERT INTO public.schema_migrations(filename) VALUES ('001_users.sql');
END
$block$;