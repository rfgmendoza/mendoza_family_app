## Table `change_proposals`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `family_group_id` | `int2` |  |
| `change_type` | `proposal_type` |  |
| `target_person_id` | `uuid` |  Nullable |
| `payload` | `jsonb` |  |
| `notes` | `text` |  Nullable |
| `status` | `proposal_status` |  |
| `proposed_by` | `uuid` |  |
| `reviewed_by` | `uuid` |  Nullable |
| `reviewed_at` | `timestamptz` |  Nullable |
| `rejection_reason` | `text` |  Nullable |
| `created_at` | `timestamptz` |  |

## Table `family_groups`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int2` | Primary |
| `name` | `text` |  |
| `spouse_name` | `text` |  Nullable |
| `deceased` | `bool` |  |
| `spouse_deceased` | `bool` |  |

## Table `people`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `legacy_id` | `text` |  |
| `family_group_id` | `int2` |  |
| `parent_id` | `uuid` |  Nullable |
| `name` | `text` |  |
| `spouse_name` | `text` |  Nullable |
| `deceased` | `bool` |  |
| `spouse_deceased` | `bool` |  |

## Table `people_details`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `person_id` | `uuid` | Primary |
| `birth_date` | `date` |  Nullable |
| `death_date` | `date` |  Nullable |
| `phone` | `text` |  Nullable |
| `email` | `text` |  Nullable |
| `city` | `text` |  Nullable |
| `photo_url` | `text` |  Nullable |
| `bio` | `text` |  Nullable |
| `social_links` | `jsonb` |  |
| `data_sharing` | `data_sharing` |  |
| `updated_at` | `timestamptz` |  |

## Table `profiles`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `person_id` | `uuid` |  Nullable |
| `created_at` | `timestamptz` |  |
| `updated_at` | `timestamptz` |  |
| `preferred_language` | `text` |  |
| `display_name` | `text` |  Nullable |
| `phone` | `numeric` |  Nullable |

## Table `reunion_registrations`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `reunion_id` | `uuid` |  |
| `registered_by` | `uuid` |  |
| `person_id` | `uuid` |  Nullable |
| `preferred_name` | `text` |  Nullable |
| `city` | `text` |  Nullable |
| `photo_url` | `text` |  Nullable |
| `guest_name` | `text` |  Nullable |
| `guest_email` | `text` |  Nullable |
| `guest_phone` | `text` |  Nullable |
| `relation_note` | `text` |  Nullable |
| `checked_in` | `bool` |  |
| `checked_in_at` | `timestamptz` |  Nullable |
| `badge_printed` | `bool` |  |
| `status` | `text` |  |
| `created_at` | `timestamptz` |  |

## Table `reunions`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `year` | `int2` |  Unique |
| `name` | `text` |  Nullable |
| `location` | `text` |  Nullable |
| `start_date` | `date` |  Nullable |
| `end_date` | `date` |  Nullable |
| `created_at` | `timestamptz` |  |

## Table `user_roles`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `user_id` | `uuid` |  |
| `role` | `user_role` |  |
| `family_group_id` | `int2` |  Nullable |
| `granted_by` | `uuid` |  Nullable |
| `created_at` | `timestamptz` |  |

