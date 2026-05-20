-- ============================================================
-- Mendoza Family App — Patch 001
-- Applies to a database that already has:
--   family_groups, people, profiles, handle_new_user trigger
-- ============================================================


-- ────────────────────────────────────────────────────────────
-- ENUMS
-- ────────────────────────────────────────────────────────────

CREATE TYPE data_sharing    AS ENUM ('open', 'ask_first', 'private');
CREATE TYPE proposal_type   AS ENUM ('edit_person', 'add_person', 'add_relationship', 'remove_relationship');
CREATE TYPE proposal_status AS ENUM ('pending', 'approved', 'rejected');
CREATE TYPE user_role       AS ENUM ('admin', 'group_rep');


-- ────────────────────────────────────────────────────────────
-- ALTER EXISTING TABLES
-- ────────────────────────────────────────────────────────────

ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS preferred_language text NOT NULL DEFAULT 'en'
    CHECK (preferred_language IN ('en', 'es')),
  ADD COLUMN IF NOT EXISTS display_name text;


-- ────────────────────────────────────────────────────────────
-- NEW TABLES (RLS enabled immediately after each)
-- ────────────────────────────────────────────────────────────

CREATE TABLE people_details (
  person_id     uuid         PRIMARY KEY REFERENCES people(id) ON DELETE CASCADE,
  birth_date    date,
  death_date    date,
  phone         text,
  email         text,
  city          text,
  photo_url     text,
  bio           text,
  social_links  jsonb        NOT NULL DEFAULT '{}',
  data_sharing  data_sharing NOT NULL DEFAULT 'ask_first',
  updated_at    timestamptz  NOT NULL DEFAULT now()
);
ALTER TABLE people_details ENABLE ROW LEVEL SECURITY;

CREATE POLICY "people_details open"
  ON people_details FOR SELECT TO authenticated
  USING (data_sharing = 'open');

CREATE POLICY "people_details own record"
  ON people_details FOR ALL TO authenticated
  USING (
    person_id IN (
      SELECT person_id FROM public.profiles WHERE id = auth.uid()
    )
  );


CREATE TABLE user_roles (
  id               uuid      PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          uuid      NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role             user_role NOT NULL,
  family_group_id  smallint  REFERENCES family_groups(id),
  granted_by       uuid      REFERENCES auth.users(id),
  created_at       timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, role, family_group_id),
  CONSTRAINT group_rep_needs_group CHECK (
    role != 'group_rep' OR family_group_id IS NOT NULL
  )
);
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "authenticated read user_roles"
  ON user_roles FOR SELECT TO authenticated USING (true);


CREATE TABLE reunions (
  id          uuid     PRIMARY KEY DEFAULT gen_random_uuid(),
  year        smallint NOT NULL UNIQUE,
  name        text,
  location    text,
  start_date  date,
  end_date    date,
  created_at  timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE reunions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "authenticated read reunions"
  ON reunions FOR SELECT TO authenticated USING (true);


CREATE TABLE reunion_registrations (
  id              uuid    PRIMARY KEY DEFAULT gen_random_uuid(),
  reunion_id      uuid    NOT NULL REFERENCES reunions(id),
  registered_by   uuid    NOT NULL REFERENCES auth.users(id),
  person_id       uuid    REFERENCES people(id),
  preferred_name  text,
  city            text,
  photo_url       text,
  guest_name      text,
  guest_email     text,
  guest_phone     text,
  relation_note   text,
  checked_in      boolean     NOT NULL DEFAULT false,
  checked_in_at   timestamptz,
  badge_printed   boolean     NOT NULL DEFAULT false,
  status          text    NOT NULL DEFAULT 'confirmed'
                          CHECK (status IN ('confirmed', 'cancelled', 'waitlisted')),
  created_at      timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT person_or_guest CHECK (
    person_id IS NOT NULL OR guest_name IS NOT NULL
  )
);
ALTER TABLE reunion_registrations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "read own registrations"
  ON reunion_registrations FOR SELECT TO authenticated
  USING (registered_by = auth.uid());

CREATE POLICY "insert own registrations"
  ON reunion_registrations FOR INSERT TO authenticated
  WITH CHECK (registered_by = auth.uid());

CREATE POLICY "update own registrations"
  ON reunion_registrations FOR UPDATE TO authenticated
  USING (registered_by = auth.uid());


CREATE TABLE change_proposals (
  id                uuid            PRIMARY KEY DEFAULT gen_random_uuid(),
  family_group_id   smallint        NOT NULL REFERENCES family_groups(id),
  change_type       proposal_type   NOT NULL,
  target_person_id  uuid            REFERENCES people(id),
  payload           jsonb           NOT NULL,
  notes             text,
  status            proposal_status NOT NULL DEFAULT 'pending',
  proposed_by       uuid            NOT NULL REFERENCES auth.users(id),
  reviewed_by       uuid            REFERENCES auth.users(id),
  reviewed_at       timestamptz,
  rejection_reason  text,
  created_at        timestamptz     NOT NULL DEFAULT now()
);
ALTER TABLE change_proposals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "read own proposals"
  ON change_proposals FOR SELECT TO authenticated
  USING (proposed_by = auth.uid());

CREATE POLICY "insert own proposals"
  ON change_proposals FOR INSERT TO authenticated
  WITH CHECK (proposed_by = auth.uid());


-- ────────────────────────────────────────────────────────────
-- INDEXES
-- ────────────────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS proposals_group_status_idx ON change_proposals(family_group_id, status);
CREATE INDEX IF NOT EXISTS proposals_proposed_by_idx  ON change_proposals(proposed_by);
CREATE INDEX IF NOT EXISTS registrations_reunion_idx  ON reunion_registrations(reunion_id);
CREATE INDEX IF NOT EXISTS registrations_person_idx   ON reunion_registrations(person_id);


-- ────────────────────────────────────────────────────────────
-- FUNCTIONS & TRIGGERS
-- ────────────────────────────────────────────────────────────

-- Fix handle_new_user to use explicit schema + search_path (resolves signup error)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO public.profiles (id) VALUES (NEW.id);
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION touch_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER people_details_updated_at
  BEFORE UPDATE ON people_details
  FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

CREATE OR REPLACE FUNCTION apply_change_proposal()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NEW.status = 'approved' AND OLD.status = 'pending' THEN
    CASE NEW.change_type

      WHEN 'edit_person' THEN
        UPDATE public.people SET
          name            = COALESCE(NEW.payload->>'name',                       name),
          spouse_name     = COALESCE(NEW.payload->>'spouse_name',                spouse_name),
          deceased        = COALESCE((NEW.payload->>'deceased')::boolean,         deceased),
          spouse_deceased = COALESCE((NEW.payload->>'spouse_deceased')::boolean,  spouse_deceased)
        WHERE id = NEW.target_person_id;

        INSERT INTO public.people_details (person_id)
          VALUES (NEW.target_person_id)
          ON CONFLICT (person_id) DO NOTHING;

        UPDATE public.people_details SET
          birth_date = COALESCE((NEW.payload->>'birth_date')::date, birth_date),
          death_date = COALESCE((NEW.payload->>'death_date')::date, death_date),
          phone      = COALESCE(NEW.payload->>'phone',     phone),
          email      = COALESCE(NEW.payload->>'email',     email),
          city       = COALESCE(NEW.payload->>'city',      city),
          photo_url  = COALESCE(NEW.payload->>'photo_url', photo_url),
          bio        = COALESCE(NEW.payload->>'bio',       bio),
          updated_at = now()
        WHERE person_id = NEW.target_person_id;

      WHEN 'add_person' THEN
        INSERT INTO public.people
          (legacy_id, family_group_id, parent_id, name, spouse_name, deceased, spouse_deceased)
        VALUES (
          NEW.payload->>'legacy_id',
          (NEW.payload->>'family_group_id')::smallint,
          (NEW.payload->>'parent_id')::uuid,
          NEW.payload->>'name',
          NEW.payload->>'spouse_name',
          COALESCE((NEW.payload->>'deceased')::boolean, false),
          COALESCE((NEW.payload->>'spouse_deceased')::boolean, false)
        );

      WHEN 'add_relationship' THEN
        IF NEW.payload->>'type' = 'parent_child' THEN
          UPDATE public.people
            SET parent_id = (NEW.payload->>'parent_id')::uuid
          WHERE id = (NEW.payload->>'child_id')::uuid;
        ELSIF NEW.payload->>'type' = 'spouse' THEN
          UPDATE public.people
            SET spouse_name = NEW.payload->>'spouse_name'
          WHERE id = (NEW.payload->>'person_id')::uuid;
        END IF;

      WHEN 'remove_relationship' THEN
        IF NEW.payload->>'type' = 'parent_child' THEN
          UPDATE public.people SET parent_id = NULL
          WHERE id = (NEW.payload->>'child_id')::uuid;
        ELSIF NEW.payload->>'type' = 'spouse' THEN
          UPDATE public.people SET spouse_name = NULL
          WHERE id = (NEW.payload->>'person_id')::uuid;
        END IF;

    END CASE;

    NEW.reviewed_at = now();
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER apply_approved_proposal
  BEFORE UPDATE ON change_proposals
  FOR EACH ROW EXECUTE FUNCTION apply_change_proposal();
