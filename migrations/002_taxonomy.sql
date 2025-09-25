-- migrations/002_taxonomy.sql
DO $block$
BEGIN
  IF EXISTS (SELECT 1 FROM public.schema_migrations WHERE filename='002_taxonomy.sql') THEN
    RAISE NOTICE '002_taxonomy.sql already applied, skipping';
    RETURN;
  END IF;

  CREATE TABLE IF NOT EXISTS app.species (
    id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    common_name_ko   text NOT NULL,         -- 예: 산양
    common_name_en   text,
    scientific_name  text,                  -- 예: Naemorhedus caudatus
    status           app.species_status NOT NULL DEFAULT 'general',
    protected_code   text,                   -- 법적 코드/등급 등(선택)
    notes            text,
    created_at       timestamptz NOT NULL DEFAULT now(),
    updated_at       timestamptz
  );

  CREATE UNIQUE INDEX IF NOT EXISTS uq_species_scientific
    ON app.species ((lower(scientific_name))) WHERE scientific_name IS NOT NULL;

  DROP TRIGGER IF EXISTS trg_species_touch ON app.species;
  CREATE TRIGGER trg_species_touch
    BEFORE UPDATE ON app.species
    FOR EACH ROW EXECUTE FUNCTION app.touch_updated_at();

  INSERT INTO public.schema_migrations(filename) VALUES ('002_taxonomy.sql');
END
$block$;