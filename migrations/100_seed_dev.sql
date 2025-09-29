-- migrations/100_seed_dev.sql
DO $$
DECLARE
  -- users
  u1 uuid; u2 uuid; u3 uuid; u4 uuid; u5 uuid;
  -- species
  sp1 uuid; sp2 uuid; sp3 uuid;
  -- media
  m1 uuid; m2 uuid; m3 uuid;
  -- sightings
  s1 uuid; s2 uuid; s3 uuid;
BEGIN
  -- 이미 실행됐다면 스킵
  IF EXISTS (
    SELECT 1 FROM public.schema_migrations WHERE filename = '100_seed_dev.sql'
  ) THEN
    RAISE NOTICE '100_seed_dev.sql already applied, skipping';
    RETURN;
  END IF;

  --------------------------------------------------------------------
  -- 👤 USERS
  --------------------------------------------------------------------
  SELECT id INTO u1 FROM app.users WHERE email='demo1@example.com';
  IF NOT FOUND THEN
    INSERT INTO app.users (email, password_hash, display_name, role)
    VALUES ('demo1@example.com','hashed_pw_1','데모유저1','user')
    RETURNING id INTO u1;
  END IF;

  SELECT id INTO u2 FROM app.users WHERE email='demo2@example.com';
  IF NOT FOUND THEN
    INSERT INTO app.users (email, password_hash, display_name, role)
    VALUES ('demo2@example.com','hashed_pw_2','데모유저2','user')
    RETURNING id INTO u2;
  END IF;

  SELECT id INTO u3 FROM app.users WHERE email='demo3@example.com';
  IF NOT FOUND THEN
    INSERT INTO app.users (email, password_hash, display_name, role)
    VALUES ('demo3@example.com','hashed_pw_3','데모유저3','moderator')
    RETURNING id INTO u3;
  END IF;

  SELECT id INTO u4 FROM app.users WHERE email='demo4@example.com';
  IF NOT FOUND THEN
    INSERT INTO app.users (email, password_hash, display_name, role)
    VALUES ('demo4@example.com','hashed_pw_4','데모유저4','user')
    RETURNING id INTO u4;
  END IF;

  SELECT id INTO u5 FROM app.users WHERE email='admin@example.com';
  IF NOT FOUND THEN
    INSERT INTO app.users (email, password_hash, display_name, role)
    VALUES ('admin@example.com','hashed_pw_admin','관리자','admin')
    RETURNING id INTO u5;
  END IF;

  --------------------------------------------------------------------
  -- 🐾 SPECIES
  --------------------------------------------------------------------
  SELECT id INTO sp1 FROM app.species WHERE scientific_name='Capra sibirica';
  IF NOT FOUND THEN
    INSERT INTO app.species (scientific_name, common_name_ko, common_name_en, status)
    VALUES ('Capra sibirica','시베리아 산양','Siberian ibex','endangered')
    RETURNING id INTO sp1;
  END IF;

  SELECT id INTO sp2 FROM app.species WHERE scientific_name='Corvus corone';
  IF NOT FOUND THEN
    INSERT INTO app.species (scientific_name, common_name_ko, common_name_en, status)
    VALUES ('Corvus corone','까마귀','Carrion crow','general')
    RETURNING id INTO sp2;
  END IF;

  SELECT id INTO sp3 FROM app.species WHERE scientific_name='Cervus nippon';
  IF NOT FOUND THEN
    INSERT INTO app.species (scientific_name, common_name_ko, common_name_en, status)
    VALUES ('Cervus nippon','꽃사슴','Sika deer','natural_monument')
    RETURNING id INTO sp3;
  END IF;

  --------------------------------------------------------------------
  -- 📷 MEDIA + 📍 SIGHTINGS
  --------------------------------------------------------------------
  -- 1) demo1 + 산양
  SELECT id INTO m1 FROM app.media
    WHERE user_id=u1 AND storage_path='/uploads/ibex1.jpg';
  IF NOT FOUND THEN
    INSERT INTO app.media (user_id, storage_path, mime_type, width, height, bytes)
    VALUES (u1, '/uploads/ibex1.jpg', 'image/jpeg', 800, 600, 123456)
    RETURNING id INTO m1;
  END IF;

  SELECT id INTO s1 FROM app.sightings
    WHERE user_id=u1 AND title='첫 산양 관찰';
  IF NOT FOUND THEN
    INSERT INTO app.sightings
      (user_id, species_id, media_id, title, description,
       occurred_at, detected_by, visibility, geom)
    VALUES
      (u1, sp1, m1, '첫 산양 관찰', '설악산에서 산양 발견',
       now() - interval '2 day', 'user', 'public',
       ST_SetSRID(ST_MakePoint(128.2::float8, 38.1::float8), 4326))
    RETURNING id INTO s1;
  END IF;

  -- 2) demo2 + 까마귀
  SELECT id INTO m2 FROM app.media
    WHERE user_id=u2 AND storage_path='/uploads/crow1.jpg';
  IF NOT FOUND THEN
    INSERT INTO app.media (user_id, storage_path, mime_type)
    VALUES (u2, '/uploads/crow1.jpg', 'image/jpeg')
    RETURNING id INTO m2;
  END IF;

  SELECT id INTO s2 FROM app.sightings
    WHERE user_id=u2 AND title='도심 속 까마귀';
  IF NOT FOUND THEN
    INSERT INTO app.sightings
      (user_id, species_id, media_id, title, description,
       occurred_at, detected_by, visibility, geom)
    VALUES
      (u2, sp2, m2, '도심 속 까마귀', '한강공원에서 관찰',
       now() - interval '1 day', 'user', 'public',
       ST_SetSRID(ST_MakePoint(127.0::float8, 37.5::float8), 4326))
    RETURNING id INTO s2;
  END IF;

  -- 3) demo3(moderator) + 꽃사슴 (AI)
  SELECT id INTO m3 FROM app.media
    WHERE user_id=u3 AND storage_path='/uploads/deer1.jpg';
  IF NOT FOUND THEN
    INSERT INTO app.media (user_id, storage_path, mime_type)
    VALUES (u3, '/uploads/deer1.jpg', 'image/jpeg')
    RETURNING id INTO m3;
  END IF;

  SELECT id INTO s3 FROM app.sightings
    WHERE user_id=u3 AND title='AI가 잡아낸 꽃사슴';
  IF NOT FOUND THEN
    INSERT INTO app.sightings
      (user_id, species_id, media_id, title, description,
       occurred_at, detected_by, ai_confidence, visibility, geom)
    VALUES
      (u3, sp3, m3, 'AI가 잡아낸 꽃사슴', '국립공원 CCTV 이미지',
       now() - interval '5 hour', 'ai', 0.923, 'public',
       ST_SetSRID(ST_MakePoint(126.9::float8, 37.4::float8), 4326))
    RETURNING id INTO s3;
  END IF;

  -- 추가 관찰(7건)
  PERFORM 1 FROM app.sightings WHERE title='산양 추가 기록';
  IF NOT FOUND THEN
    INSERT INTO app.sightings
      (user_id, species_id, title, description, occurred_at, detected_by, ai_confidence, visibility, geom)
    VALUES
      (u4, sp1, '산양 추가 기록', '다른 위치에서 관찰',
         now() - interval '3 day','user', NULL,'public',
         ST_SetSRID(ST_MakePoint(127.5::float8, 37.6::float8),4326)),
      (u5, sp2, '까마귀 무리', '여러 마리 관찰',
         now() - interval '4 day','user', NULL,'private',
         ST_SetSRID(ST_MakePoint(129.0::float8, 35.2::float8),4326)),
      (u1, sp3, '꽃사슴 가족', '3마리 관찰',
         now() - interval '7 day','user', NULL,'public',
         ST_SetSRID(ST_MakePoint(126.5::float8, 33.5::float8),4326)),
      (u2, sp1, '산양 흔적', '발자국 발견',
         now() - interval '2 hour','user', NULL,'public',
         ST_SetSRID(ST_MakePoint(127.3::float8, 36.4::float8),4326)),
      (u3, sp2, '까마귀 소리', '울음소리만 들음',
         now() - interval '12 hour','user', NULL,'public',
         ST_SetSRID(ST_MakePoint(127.1::float8, 37.2::float8),4326)),
      (u4, sp3, '꽃사슴 영상', '드론 촬영',
         now() - interval '10 day','ai',0.812,'public',
         ST_SetSRID(ST_MakePoint(128.9::float8, 35.8::float8),4326)),
      (u5, sp1, '산양 긴급', '도로 근처 발견',
         now() - interval '30 min','user', NULL,'public',
         ST_SetSRID(ST_MakePoint(127.8::float8, 37.9::float8),4326));
  END IF;

  --------------------------------------------------------------------
  -- 💬 COMMENTS
  --------------------------------------------------------------------
  PERFORM 1 FROM app.comments WHERE body='와, 멋지네요!';
  IF NOT FOUND THEN
    INSERT INTO app.comments (sighting_id, user_id, body)
    SELECT s1, u2, '와, 멋지네요!' WHERE s1 IS NOT NULL;
  END IF;

  PERFORM 1 FROM app.comments WHERE body='이 근처 자주 나오나요?';
  IF NOT FOUND THEN
    INSERT INTO app.comments (sighting_id, user_id, body)
    SELECT s2, u3, '이 근처 자주 나오나요?' WHERE s2 IS NOT NULL;
  END IF;

  PERFORM 1 FROM app.comments WHERE body='AI 판정이라 흥미롭네요';
  IF NOT FOUND THEN
    INSERT INTO app.comments (sighting_id, user_id, body)
    SELECT s3, u4, 'AI 판정이라 흥미롭네요' WHERE s3 IS NOT NULL;
  END IF;

  --------------------------------------------------------------------
  -- ❤️ LIKES
  --------------------------------------------------------------------
  PERFORM 1 FROM app.likes WHERE user_id=u5;
  IF NOT FOUND THEN
    INSERT INTO app.likes (sighting_id, user_id)
    SELECT id, u5 FROM app.sightings ORDER BY random() LIMIT 3;
  END IF;

  PERFORM 1 FROM app.likes WHERE user_id=u1;
  IF NOT FOUND THEN
    INSERT INTO app.likes (sighting_id, user_id)
    SELECT id, u1 FROM app.sightings ORDER BY random() LIMIT 2;
  END IF;

  --------------------------------------------------------------------
  -- 🚩 REPORTS
  --------------------------------------------------------------------
  PERFORM 1 FROM app.reports WHERE reason='위치 정보가 부정확합니다';
  IF NOT FOUND THEN
    INSERT INTO app.reports (sighting_id, reporter_id, reason)
    SELECT id, u4, '위치 정보가 부정확합니다'
    FROM app.sightings
    WHERE visibility='public'
    ORDER BY created_at DESC
    LIMIT 1;
  END IF;

  --------------------------------------------------------------------
  -- 적용 기록
  --------------------------------------------------------------------
  INSERT INTO public.schema_migrations(filename)
  VALUES ('100_seed_dev.sql');

END $$;