-- migrations/005_views_and_functions.sql
DO $block$
BEGIN
  IF EXISTS (SELECT 1 FROM public.schema_migrations WHERE filename='005_views_and_functions.sql') THEN
    RAISE NOTICE '005_views_and_functions.sql already applied, skipping';
    RETURN;
  END IF;

  -- 지도: (lon, lat, radius_km) 주변 카운터
  CREATE OR REPLACE FUNCTION app.fn_nearby_counts(lon double precision, lat double precision, radius_km double precision)
  RETURNS TABLE(
    total_count bigint,
    general_count bigint,
    endangered_count bigint,
    natural_monument_count bigint
  )
  LANGUAGE sql STABLE AS
  $$
    SELECT
      COUNT(*) FILTER (WHERE s.visibility = 'public')                                           AS total_count,
      COUNT(*) FILTER (WHERE sp.status='general'          AND s.visibility='public')            AS general_count,
      COUNT(*) FILTER (WHERE sp.status='endangered'       AND s.visibility='public')            AS endangered_count,
      COUNT(*) FILTER (WHERE sp.status='natural_monument' AND s.visibility='public')            AS natural_monument_count
    FROM app.sightings s
    LEFT JOIN app.species sp ON sp.id = s.species_id
    WHERE s.geom IS NOT NULL
      AND ST_DWithin(
            s.geom::geography,
            ST_SetSRID(ST_MakePoint(lon, lat), 4326)::geography,
            radius_km * 1000
          );
  $$;

  -- 지도 리스트(반경 내 최근 관찰 N건)
  CREATE OR REPLACE FUNCTION app.fn_nearby_sightings(lon double precision, lat double precision, radius_km double precision, limit_n int)
  RETURNS TABLE(
    id uuid, title text, description text, common_name_ko text, status app.species_status,
    occurred_at timestamptz, ai_confidence numeric, address_text text,
    user_id uuid, media_id uuid
  )
  LANGUAGE sql STABLE AS
  $$
    SELECT s.id, s.title, s.description, sp.common_name_ko, sp.status,
           COALESCE(s.occurred_at, s.created_at) AS occurred_at,
           s.ai_confidence, s.address_text, s.user_id, s.media_id
    FROM app.sightings s
    LEFT JOIN app.species sp ON sp.id = s.species_id
    WHERE s.visibility='public'
      AND s.geom IS NOT NULL
      AND ST_DWithin(
            s.geom::geography,
            ST_SetSRID(ST_MakePoint(lon, lat), 4326)::geography,
            radius_km * 1000
          )
    ORDER BY COALESCE(s.occurred_at, s.created_at) DESC
    LIMIT limit_n;
  $$;

  -- 커뮤니티 피드(최근 관찰)
  CREATE OR REPLACE VIEW app.v_recent_feed AS
  SELECT
    s.id,
    sp.common_name_ko AS species_name,
    sp.status,
    s.title,
    s.description,
    s.ai_confidence,
    s.address_text,
    s.user_id,
    s.media_id,
    COALESCE(s.occurred_at, s.created_at) AS occurred_at
  FROM app.sightings s
  LEFT JOIN app.species sp ON sp.id = s.species_id
  WHERE s.visibility='public'
  ORDER BY COALESCE(s.occurred_at, s.created_at) DESC;

  -- 프로필: 유저별 상위 종 집계
  CREATE OR REPLACE VIEW app.v_user_top_species AS
  SELECT
    u.id AS user_id,
    sp.common_name_ko,
    sp.status,
    COUNT(*) AS cnt,
    RANK() OVER (PARTITION BY u.id ORDER BY COUNT(*) DESC) AS rnk
  FROM app.users u
  JOIN app.sightings s ON s.user_id = u.id AND s.visibility='public'
  LEFT JOIN app.species sp ON sp.id = s.species_id
  GROUP BY u.id, sp.common_name_ko, sp.status;

  -- 프로필: 유저별 월간 추이
  CREATE OR REPLACE VIEW app.v_user_monthly_counts AS
  SELECT
    s.user_id,
    date_trunc('month', COALESCE(s.occurred_at, s.created_at)) AS month,
    COUNT(*) AS cnt
  FROM app.sightings s
  WHERE s.visibility='public'
  GROUP BY s.user_id, date_trunc('month', COALESCE(s.occurred_at, s.created_at))
  ORDER BY s.user_id, month;

  INSERT INTO public.schema_migrations(filename) VALUES ('005_views_and_functions.sql');
END
$block$;