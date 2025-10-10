# Memorio Database Schema Documentation

**Version:** 1.0.0  
**Last Updated:** October 10, 2025

## Overview

The Memorio database is designed as a multi-tenant SaaS platform for funeral homes to manage obituary creation and tribute media production. The schema enforces strict role-based access control (RBAC) through PostgreSQL Row Level Security (RLS) policies.

## Architecture Principles

1. **Multi-Tenancy**: Organizations are completely isolated at the database level
2. **Role Hierarchy**: Admin → Director → Family + Editor (assignment-based)
3. **Immutability**: Audit logs and form version history are append-only
4. **Security First**: All tables have RLS enabled with explicit policies
5. **Extensibility**: JSONB columns for flexible metadata storage

## Entity Relationship Diagram

```
┌─────────────────┐
│  organizations  │
└────────┬────────┘
         │
         │ (org_id)
         │
    ┌────▼────────────────┐
    │       users         │
    └────────┬────────────┘
             │
        ┌────┴────┐
        │         │
    (created_by)  (assigned_family_user_id)
        │         │
    ┌───▼─────────▼───┐
    │      cases      │
    └───┬─────────────┘
        │
   ┌────┼────┬─────┐
   │    │    │     │
   │    │    │     │
┌──▼──┐ │ ┌──▼──┐ │
│forms│ │ │assets│ │
└─────┘ │ └─────┘ │
        │         │
   ┌────▼──┐ ┌────▼─────────┐
   │events │ │notifications │
   └───────┘ └──────────────┘
        │
   ┌────▼────────────────┐
   │editor_assignments   │
   └─────────────────────┘
```

## Table Reference

### 1. organizations

**Purpose**: Represents funeral homes using the Memorio platform

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | Unique organization identifier |
| `name` | TEXT | NOT NULL | Funeral home name |
| `contact_email` | TEXT | NOT NULL | Primary contact email |
| `contact_phone` | TEXT | | Contact phone number |
| `region` | TEXT | | Geographic region |
| `branding_metadata` | JSONB | | Logo, colors, website |
| `status` | TEXT | CHECK | `active`, `suspended`, `archived` |
| `created_at` | TIMESTAMPTZ | | Auto-set on creation |
| `updated_at` | TIMESTAMPTZ | | Auto-updated on change |

**RLS Policies**:
- Admins: Full access
- Directors: Read-only for their own org
- Support: Read-only for all orgs

---

### 2. users

**Purpose**: All user accounts across all roles

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY → auth.users | Links to Supabase Auth |
| `email` | TEXT | UNIQUE, NOT NULL | User email address |
| `role` | TEXT | CHECK, NOT NULL | `admin`, `director`, `family`, `editor`, `support` |
| `org_id` | UUID | FK → organizations | NULL for global roles |
| `status` | TEXT | CHECK | `invited`, `active`, `suspended`, `archived` |
| `metadata` | JSONB | | Name, phone, preferences |
| `created_at` | TIMESTAMPTZ | | Account creation time |
| `updated_at` | TIMESTAMPTZ | | Last profile update |
| `last_login_at` | TIMESTAMPTZ | | Last authentication |

**RLS Policies**:
- Admins: Full access to all users
- Directors: Full access to users in their org
- All users: Read/update their own profile
- Support: Read-only for all users

**Indexes**:
- `idx_users_org_id` on `(org_id)`
- `idx_users_role` on `(role)`
- `idx_users_email` on `(email)`

---

### 3. cases

**Purpose**: Individual obituary/tribute cases

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | Unique case identifier |
| `org_id` | UUID | FK → organizations, NOT NULL | Owning organization |
| `deceased_name` | TEXT | NOT NULL | Name of deceased |
| `created_by` | UUID | FK → users, NOT NULL | Director who created case |
| `assigned_family_user_id` | UUID | FK → users | Family member account |
| `status` | TEXT | CHECK | Workflow state (see below) |
| `sla_start_at` | TIMESTAMPTZ | | When SLA timer started |
| `sla_state` | TEXT | CHECK | `on_time`, `warning`, `breach` |
| `metadata` | JSONB | | Service date, notes, etc. |
| `created_at` | TIMESTAMPTZ | | Case creation time |
| `updated_at` | TIMESTAMPTZ | | Last modification |

**Status Workflow**:
1. `created` → Director creates case
2. `waiting_on_family` → Family invited, not started
3. `intake_in_progress` → Family working on form
4. `submitted` → Family submitted form
5. `in_production` → Editor working on obituary
6. `awaiting_review` → Waiting for approval
7. `delivered` → Completed and sent
8. `closed` → Archived

**RLS Policies**:
- Admins: Full access
- Directors: Full access to cases in their org
- Family: Read/update their assigned cases only
- Editors: Read/update cases they're assigned to
- Support: Read-only for all cases

**Indexes**:
- `idx_cases_org_id` on `(org_id)`
- `idx_cases_status` on `(status)`
- `idx_cases_assigned_family` on `(assigned_family_user_id)`

---

### 4. forms

**Purpose**: Stores intake form data from families

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | Unique form identifier |
| `case_id` | UUID | FK → cases, NOT NULL | Associated case |
| `json_schema_version` | TEXT | NOT NULL, DEFAULT 'v1' | Form schema version |
| `draft_json` | JSONB | | In-progress form data |
| `submitted_json` | JSONB | | Final submitted data |
| `submitted_at` | TIMESTAMPTZ | | Submission timestamp |
| `immutable_version_history` | JSONB | | Array of past submissions |
| `created_at` | TIMESTAMPTZ | | Form creation time |
| `updated_at` | TIMESTAMPTZ | | Last modification |

**Version History Structure**:
```json
[
  {
    "version": 1,
    "submitted_at": "2025-10-10T12:00:00Z",
    "submitted_by": "uuid",
    "data": { /* full form payload */ }
  }
]
```

**RLS Policies**:
- Admins: Full access
- Directors: Full access to forms in their org
- Family: Full access to their assigned case forms
- Editors: Read-only for assigned case forms
- Support: Read-only for all forms

**Triggers**:
- `maintain_form_version_history`: Appends to version history on submit
- `update_case_on_form_submit`: Changes case status to 'submitted'

---

### 5. assets

**Purpose**: Tracks uploaded photos and videos

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | Unique asset identifier |
| `case_id` | UUID | FK → cases, NOT NULL | Associated case |
| `uploader_user_id` | UUID | FK → users, NOT NULL | Who uploaded it |
| `file_key` | TEXT | NOT NULL | Path in Supabase Storage |
| `mime_type` | TEXT | NOT NULL | File type (image/jpeg, etc.) |
| `size_bytes` | BIGINT | NOT NULL | File size |
| `dedupe_hash` | TEXT | | SHA-256 for duplicate detection |
| `uploaded_at` | TIMESTAMPTZ | | Upload timestamp |
| `metadata` | JSONB | | EXIF data, original filename |

**Storage Integration**:
- Bucket: `case-assets`
- Path structure: `{org_id}/{case_id}/{file_key}`

**RLS Policies**:
- Admins: Full access
- Directors: Full access to assets in their org
- Family: Full access to their case assets
- Editors: Read-only for assigned case assets

**Indexes**:
- `idx_assets_case_id` on `(case_id)`
- `idx_assets_dedupe_hash` on `(dedupe_hash)`

---

### 6. editor_assignments

**Purpose**: Maps editors to cases they're working on

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | Unique assignment ID |
| `case_id` | UUID | FK → cases, NOT NULL | Assigned case |
| `editor_user_id` | UUID | FK → users, NOT NULL | Assigned editor |
| `assigned_by` | UUID | FK → users, NOT NULL | Director who assigned |
| `assigned_at` | TIMESTAMPTZ | | Assignment time |
| `unassigned_at` | TIMESTAMPTZ | | NULL = still assigned |

**RLS Policies**:
- Admins: Full access
- Directors: Full access to assignments in their org
- Editors: Read-only for their own assignments

**Indexes**:
- `idx_editor_assignments_active` on `(case_id, editor_user_id)` WHERE `unassigned_at IS NULL`

---

### 7. events

**Purpose**: Immutable audit log of all actions

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | Unique event ID |
| `actor_user_id` | UUID | FK → users | Who performed action |
| `actor_role` | TEXT | | Role at time of action |
| `action_type` | TEXT | NOT NULL | INSERT/UPDATE/DELETE |
| `target_type` | TEXT | NOT NULL | Table name |
| `target_id` | UUID | | Affected row ID |
| `payload` | JSONB | | Full change context |
| `timestamp` | TIMESTAMPTZ | | Event time |

**RLS Policies**:
- Admins: Full access
- Directors: Read events for their org's data
- Support: Read-only for all events

**Triggers**:
- Auto-populated via `log_audit_event()` function on critical tables

---

### 8. notifications

**Purpose**: Email/SMS notification queue

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | Unique notification ID |
| `case_id` | UUID | FK → cases | Related case |
| `event_type` | TEXT | NOT NULL | Notification trigger |
| `recipients` | JSONB | NOT NULL | Array of emails/phones |
| `sent_at` | TIMESTAMPTZ | | Delivery timestamp |
| `status` | TEXT | CHECK | `pending`, `sent`, `failed` |
| `created_at` | TIMESTAMPTZ | | Queued time |

**Event Types**:
- `case_created`: Director creates new case
- `family_invited`: Family account generated
- `form_submitted`: Family completes intake
- `delivery_ready`: Obituary completed

---

### 9. exports

**Purpose**: Data export and report generation

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | Unique export ID |
| `case_id` | UUID | FK → cases | Single case export |
| `org_id` | UUID | FK → organizations | Bulk org export |
| `export_type` | TEXT | CHECK, NOT NULL | `csv`, `zip`, `pdf` |
| `file_url` | TEXT | | Signed download URL |
| `created_by` | UUID | FK → users, NOT NULL | Requester |
| `created_at` | TIMESTAMPTZ | | Request time |
| `expires_at` | TIMESTAMPTZ | | URL expiration |

---

## Security Model

### JWT Claims Structure

Supabase Auth JWTs include custom claims for RLS:

```json
{
  "sub": "user-uuid",
  "email": "user@example.com",
  "role": "director",
  "org_id": "org-uuid"
}
```

### RLS Policy Patterns

1. **Global Access (Admin/Support)**:
   ```sql
   USING (auth.jwt() ->> 'role' = 'admin')
   ```

2. **Organization-Scoped (Director)**:
   ```sql
   USING (
     auth.jwt() ->> 'role' = 'director' AND
     org_id = (auth.jwt() ->> 'org_id')::uuid
   )
   ```

3. **Assignment-Scoped (Editor)**:
   ```sql
   USING (
     auth.jwt() ->> 'role' = 'editor' AND
     EXISTS (
       SELECT 1 FROM editor_assignments
       WHERE case_id = cases.id
       AND editor_user_id = auth.uid()
       AND unassigned_at IS NULL
     )
   )
   ```

---

## Database Functions

### `update_updated_at_column()`
Automatically updates `updated_at` timestamp on row modifications.

### `log_audit_event()`
Creates immutable audit trail in `events` table for all important changes.

### `append_form_version_history()`
Maintains versioned history of form submissions.

### `update_case_on_form_submission()`
Transitions case status when family submits intake form.

---

## Migration Strategy

Migrations are sequentially numbered and idempotent:

1. `001_initial_schema.sql` - Core tables and indexes
2. `002_rls_policies.sql` - Security policies
3. `003_functions_triggers.sql` - Automation
4. `004_seed_data.sql` - Test data

**Apply via Supabase CLI**:
```bash
supabase db push
```

---

## Testing & Validation

See `scripts/create-test-accounts.js` to generate test users for each role.

**Validation checklist**:
- [ ] All tables created
- [ ] Foreign keys enforce referential integrity
- [ ] RLS blocks cross-tenant access
- [ ] Admins can access all data
- [ ] Directors isolated to their org
- [ ] Families isolated to assigned cases
- [ ] Editors isolated to assigned cases
- [ ] Audit triggers fire on changes
- [ ] Form version history appends correctly
- [ ] Storage bucket accessible

---

## Future Considerations

1. **Partitioning**: Partition `events` table by month for performance
2. **Archival**: Move closed cases to cold storage after 1 year
3. **GDPR**: Implement data deletion/anonymization workflows
4. **Replication**: Add read replicas for reporting queries
5. **Encryption**: Column-level encryption for sensitive PII

---

**End of Schema Documentation**

