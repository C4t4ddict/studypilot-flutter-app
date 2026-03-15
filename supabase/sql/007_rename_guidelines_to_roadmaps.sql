-- Rename legacy guideline schema to roadmap schema
-- Safe to run after 003_planner_core.sql on existing projects.

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'guidelines'
  ) THEN
    ALTER TABLE public.guidelines RENAME TO roadmaps;
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'curriculums' AND column_name = 'guideline_id'
  ) THEN
    ALTER TABLE public.curriculums RENAME COLUMN guideline_id TO roadmap_id;
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'curriculums_guideline_id_fkey'
  ) THEN
    ALTER TABLE public.curriculums DROP CONSTRAINT curriculums_guideline_id_fkey;
  END IF;
END $$;

ALTER TABLE public.curriculums
  ADD CONSTRAINT curriculums_roadmap_id_fkey
  FOREIGN KEY (roadmap_id) REFERENCES public.roadmaps(id) ON DELETE CASCADE;

ALTER TABLE public.roadmaps ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname='public' AND tablename='roadmaps' AND policyname='guidelines_owner_all'
  ) THEN
    DROP POLICY guidelines_owner_all ON public.roadmaps;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname='public' AND tablename='roadmaps' AND policyname='roadmaps_owner_all'
  ) THEN
    CREATE POLICY roadmaps_owner_all
    ON public.roadmaps
    FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;
