-- migrations/003_media_and_sightings.sql
DO $block$
BEGIN
  IF EXISTS (SELECT 1 FROM public.schema_migrations WHERE filename='003_media_and_sightings.sql') THEN
    RAISE NOTICE '003_media_and_sightings.sql already applied, skipping';
    RETURN;
  END IF;

  -- 업로드 미디어(원본/리사이즈 경로 등은 백엔드 정책에 맞춤)
  CREATE TABLE IF NOT EXISTS app.media (
    id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      uuid NOT NULL REFERENCES app.users(id) ON DELETE CASCADE,
    storage_path text NOT NULL,        -- 예: s3://bucket/.. 또는 /uploads/..
    mime_type    text,
    width        int,
    height       int,
    bytes        bigint,
    checksum     text,                 -- 중복 방지용(선택)
    created_at   timestamptz NOT NULL DEFAULT now()
  );
  CREATE INDEX IF NOT EXISTS idx_media_user ON app.media(user_id);

  -- 관찰기록(지도 + 커뮤니티 피드의 기본 단위)
  CREATE TABLE IF NOT EXISTS app.sightings (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       uuid NOT NULL REFERENCES app.users(id) ON DELETE CASCADE,
    species_id    uuid REFERENCES app.species(id),
    media_id      uuid REFERENCES app.media(id),
    title         text,                        -- 커뮤니티 카드 제목(선택)
    description   text,                        -- 메모/설명
    occurred_at   timestamptz,                 -- 관찰 시각(없으면 created_at)
    detected_by   app.detected_by NOT NULL DEFAULT 'user',
    ai_confidence numeric(5,3) CHECK (ai_confidence BETWEEN 0 AND 1),
    visibility    app.visibility NOT NULL DEFAULT 'public',
    is_verified   boolean NOT NULL DEFAULT false, -- 관리자/전문가 검증여부
    address_text  text,                        -- 역지오코딩 텍스트(선택)
    geom          geometry(Point, 4326),       -- 지도 위치
    created_at    timestamptz NOT NULL DEFAULT now(),
    updated_at    timestamptz
  );

  -- 인덱스들
  CREATE INDEX IF NOT EXISTS idx_sightings_user       ON app.sightings(user_id);
  CREATE INDEX IF NOT EXISTS idx_sightings_species    ON app.sightings(species_id);
  CREATE INDEX IF NOT EXISTS idx_sightings_occurred   ON app.sightings(occurred_at);
  CREATE INDEX IF NOT EXISTS idx_sightings_geom_gist  ON app.sightings USING GIST (geom);
  CREATE INDEX IF NOT EXISTS idx_sightings_visibility ON app.sightings(visibility);

  -- updated_at 트리거
  DROP TRIGGER IF EXISTS trg_sightings_touch ON app.sightings;
  CREATE TRIGGER trg_sightings_touch
    BEFORE UPDATE ON app.sightings
    FOR EACH ROW EXECUTE FUNCTION app.touch_updated_at();

  -- (선택) AI 디텍션 상세(바운딩박스 등) - 한 이미지에 여러 객체
  CREATE TABLE IF NOT EXISTS app.ai_detections (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    media_id    uuid NOT NULL REFERENCES app.media(id) ON DELETE CASCADE,
    label       text NOT NULL,                 -- 모델 라벨(예: "roe_deer")
    score       numeric(5,3) CHECK (score BETWEEN 0 AND 1),
    x_min       numeric(6,3) CHECK (x_min BETWEEN 0 AND 1),
    y_min       numeric(6,3) CHECK (y_min BETWEEN 0 AND 1),
    x_max       numeric(6,3) CHECK (x_max BETWEEN 0 AND 1),
    y_max       numeric(6,3) CHECK (y_max BETWEEN 0 AND 1),
    created_at  timestamptz NOT NULL DEFAULT now()
  );
  CREATE INDEX IF NOT EXISTS idx_ai_detections_media ON app.ai_detections(media_id);

  INSERT INTO public.schema_migrations(filename) VALUES ('003_media_and_sightings.sql');
END
$block$;