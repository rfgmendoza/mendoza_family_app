-- ============================================================
-- Mendoza Family App — Supabase Schema
-- Run this in full before running seed.sql
-- ============================================================


-- ────────────────────────────────────────────────────────────
-- ENUMS
-- ────────────────────────────────────────────────────────────

CREATE TYPE data_sharing    AS ENUM ('open', 'ask_first', 'private');
CREATE TYPE proposal_type   AS ENUM ('edit_person', 'add_person', 'add_relationship', 'remove_relationship');
CREATE TYPE proposal_status AS ENUM ('pending', 'approved', 'rejected');
CREATE TYPE user_role       AS ENUM ('admin', 'group_rep');


-- ────────────────────────────────────────────────────────────
-- CORE FAMILY TREE
-- ────────────────────────────────────────────────────────────

CREATE TABLE family_groups (
  id               smallint PRIMARY KEY,   -- 1–7, matches legacy JSON
  name             text     NOT NULL,
  spouse_name      text,
  deceased         boolean  NOT NULL DEFAULT false,
  spouse_deceased  boolean  NOT NULL DEFAULT false
);

CREATE TABLE people (
  id               uuid     PRIMARY KEY DEFAULT gen_random_uuid(),
  legacy_id        text     NOT NULL,      -- original hierarchical ID ("111", "1a", "113A")
  family_group_id  smallint NOT NULL REFERENCES family_groups(id),
  parent_id        uuid     REFERENCES people(id),   -- NULL for the 7 group roots
  name             text     NOT NULL,
  spouse_name      text,
  deceased         boolean  NOT NULL DEFAULT false,
  spouse_deceased  boolean  NOT NULL DEFAULT false
);

-- Optional demographic data for family members
CREATE TABLE people_details (
  person_id     uuid         PRIMARY KEY REFERENCES people(id) ON DELETE CASCADE,
  birth_date    date,
  death_date    date,
  phone         text,
  email         text,
  city          text,
  photo_url     text,
  bio           text,
  -- jsonb for flexibility: {"instagram": "...", "facebook": "...", "linkedin": "..."}
  social_links  jsonb        NOT NULL DEFAULT '{}',
  data_sharing  data_sharing NOT NULL DEFAULT 'ask_first',
  updated_at    timestamptz  NOT NULL DEFAULT now()
);


-- ────────────────────────────────────────────────────────────
-- AUTH & PROFILES
-- ────────────────────────────────────────────────────────────

-- Links a Supabase auth user to their family member record.
-- person_id is NULL until the user completes the "who are you?" step.
CREATE TABLE profiles (
  id                  uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  person_id           uuid REFERENCES people(id),
  preferred_language  text NOT NULL DEFAULT 'en' CHECK (preferred_language IN ('en', 'es')),
  display_name        text,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now()
);

-- Role-based access: site-wide admins and per-group representatives
CREATE TABLE user_roles (
  id               uuid      PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          uuid      NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role             user_role NOT NULL,
  family_group_id  smallint  REFERENCES family_groups(id),  -- NULL for admin, required for group_rep
  granted_by       uuid      REFERENCES auth.users(id),
  created_at       timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, role, family_group_id),
  CONSTRAINT group_rep_needs_group CHECK (
    role != 'group_rep' OR family_group_id IS NOT NULL
  )
);


-- ────────────────────────────────────────────────────────────
-- REUNIONS
-- ────────────────────────────────────────────────────────────

CREATE TABLE reunions (
  id          uuid     PRIMARY KEY DEFAULT gen_random_uuid(),
  year        smallint NOT NULL UNIQUE,
  name        text,
  location    text,
  start_date  date,
  end_date    date,
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- One row = one badge. Covers both family members and non-member guests.
CREATE TABLE reunion_registrations (
  id              uuid    PRIMARY KEY DEFAULT gen_random_uuid(),
  reunion_id      uuid    NOT NULL REFERENCES reunions(id),
  registered_by   uuid    NOT NULL REFERENCES auth.users(id),

  -- who this badge is for (one of person_id or guest_name must be set)
  person_id       uuid    REFERENCES people(id),
  preferred_name  text,   -- display name on badge (overrides people.name if set)
  city            text,   -- hometown, shown on badge
  photo_url       text,   -- badge photo (overrides people_details.photo_url for members)

  -- non-member / guest fields
  guest_name      text,
  guest_email     text,
  guest_phone     text,
  relation_note   text,   -- "Guest of Rafael Mendoza" — printed on badge

  -- event day
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


-- ────────────────────────────────────────────────────────────
-- CHANGE PROPOSALS
-- ────────────────────────────────────────────────────────────

CREATE TABLE change_proposals (
  id                uuid            PRIMARY KEY DEFAULT gen_random_uuid(),
  family_group_id   smallint        NOT NULL REFERENCES family_groups(id),
  change_type       proposal_type   NOT NULL,
  target_person_id  uuid            REFERENCES people(id),  -- NULL for add_person
  payload           jsonb           NOT NULL,
  notes             text,
  status            proposal_status NOT NULL DEFAULT 'pending',
  proposed_by       uuid            NOT NULL REFERENCES auth.users(id),
  reviewed_by       uuid            REFERENCES auth.users(id),
  reviewed_at       timestamptz,
  rejection_reason  text,
  created_at        timestamptz     NOT NULL DEFAULT now()
);


-- ────────────────────────────────────────────────────────────
-- INDEXES
-- ────────────────────────────────────────────────────────────

-- Tree traversal and path-finding
CREATE INDEX people_parent_id_idx       ON people(parent_id);

-- Family group filtering (UI toggle 1–7)
CREATE INDEX people_group_idx           ON people(family_group_id);

-- Legacy ID lookup (relationship algorithm and QR resolution)
CREATE INDEX people_legacy_id_idx       ON people(family_group_id, legacy_id);

-- Full-text search across name and spouse_name
CREATE INDEX people_name_search_idx     ON people
  USING gin(to_tsvector('simple', name || ' ' || coalesce(spouse_name, '')));

-- Proposal queue lookups
CREATE INDEX proposals_group_status_idx ON change_proposals(family_group_id, status);
CREATE INDEX proposals_proposed_by_idx  ON change_proposals(proposed_by);

-- Reunion registration lookups
CREATE INDEX registrations_reunion_idx  ON reunion_registrations(reunion_id);
CREATE INDEX registrations_person_idx   ON reunion_registrations(person_id);


-- ────────────────────────────────────────────────────────────
-- FUNCTIONS & TRIGGERS
-- ────────────────────────────────────────────────────────────

-- Auto-create a profile row when a new user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO public.profiles (id) VALUES (NEW.id);
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Keep updated_at columns current
CREATE OR REPLACE FUNCTION touch_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

CREATE TRIGGER people_details_updated_at
  BEFORE UPDATE ON people_details
  FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

-- Automatically apply an approved change proposal to the family tree
CREATE OR REPLACE FUNCTION apply_change_proposal()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NEW.status = 'approved' AND OLD.status = 'pending' THEN
    CASE NEW.change_type

      WHEN 'edit_person' THEN
        -- Apply any people-level fields present in payload
        UPDATE public.people SET
          name            = COALESCE(NEW.payload->>'name',            name),
          spouse_name     = COALESCE(NEW.payload->>'spouse_name',     spouse_name),
          deceased        = COALESCE((NEW.payload->>'deceased')::boolean,        deceased),
          spouse_deceased = COALESCE((NEW.payload->>'spouse_deceased')::boolean, spouse_deceased)
        WHERE id = NEW.target_person_id;

        -- Upsert people_details fields if any are present in payload
        INSERT INTO public.people_details (person_id)
          VALUES (NEW.target_person_id)
          ON CONFLICT (person_id) DO NOTHING;

        UPDATE public.people_details SET
          birth_date = COALESCE((NEW.payload->>'birth_date')::date, birth_date),
          death_date = COALESCE((NEW.payload->>'death_date')::date, death_date),
          phone      = COALESCE(NEW.payload->>'phone',  phone),
          email      = COALESCE(NEW.payload->>'email',  email),
          city       = COALESCE(NEW.payload->>'city',   city),
          photo_url  = COALESCE(NEW.payload->>'photo_url', photo_url),
          bio        = COALESCE(NEW.payload->>'bio',    bio),
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
          UPDATE public.people
            SET parent_id = NULL
          WHERE id = (NEW.payload->>'child_id')::uuid;
        ELSIF NEW.payload->>'type' = 'spouse' THEN
          UPDATE public.people
            SET spouse_name = NULL
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


-- ────────────────────────────────────────────────────────────
-- ROW LEVEL SECURITY
-- ────────────────────────────────────────────────────────────

ALTER TABLE family_groups          ENABLE ROW LEVEL SECURITY;
ALTER TABLE people                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE people_details         ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles               ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_roles             ENABLE ROW LEVEL SECURITY;
ALTER TABLE reunions               ENABLE ROW LEVEL SECURITY;
ALTER TABLE reunion_registrations  ENABLE ROW LEVEL SECURITY;
ALTER TABLE change_proposals       ENABLE ROW LEVEL SECURITY;

-- Core tree: readable by all authenticated users
CREATE POLICY "authenticated read family_groups"
  ON family_groups FOR SELECT TO authenticated USING (true);

CREATE POLICY "authenticated read people"
  ON people FOR SELECT TO authenticated USING (true);

-- people_details: visibility controlled by the data_sharing flag
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

-- Profiles: users see and edit only their own
CREATE POLICY "own profile read"
  ON profiles FOR SELECT TO authenticated
  USING (id = auth.uid());

CREATE POLICY "own profile update"
  ON profiles FOR UPDATE TO authenticated
  USING (id = auth.uid()) WITH CHECK (id = auth.uid());

-- User roles: readable by authenticated, managed by admins only (enforced in app layer)
CREATE POLICY "authenticated read user_roles"
  ON user_roles FOR SELECT TO authenticated USING (true);

-- Reunions: readable by all authenticated users
CREATE POLICY "authenticated read reunions"
  ON reunions FOR SELECT TO authenticated USING (true);

-- Registrations: users see registrations they submitted; admins handled in app layer
CREATE POLICY "read own registrations"
  ON reunion_registrations FOR SELECT TO authenticated
  USING (registered_by = auth.uid());

CREATE POLICY "insert own registrations"
  ON reunion_registrations FOR INSERT TO authenticated
  WITH CHECK (registered_by = auth.uid());

CREATE POLICY "update own registrations"
  ON reunion_registrations FOR UPDATE TO authenticated
  USING (registered_by = auth.uid());

-- Change proposals: proposers see their own; group reps and admins handled in app layer
CREATE POLICY "read own proposals"
  ON change_proposals FOR SELECT TO authenticated
  USING (proposed_by = auth.uid());

CREATE POLICY "insert own proposals"
  ON change_proposals FOR INSERT TO authenticated
  WITH CHECK (proposed_by = auth.uid());
