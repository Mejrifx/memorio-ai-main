# Memorio Security Policies Documentation

**Version:** 1.0.0  
**Last Updated:** October 10, 2025

## Overview

Memorio implements database-level security through PostgreSQL Row Level Security (RLS). Every table has explicit policies that enforce the role-based access control (RBAC) model.

## Security Architecture

### Core Principles

1. **Defense in Depth**: Security enforced at database, API, and application layers
2. **Least Privilege**: Users can only access data necessary for their role
3. **Multi-Tenancy**: Complete data isolation between organizations
4. **Audit Trail**: All sensitive actions logged immutably
5. **Invitation-Only**: No public registration; all accounts created via invite chain

### Role Hierarchy

```
┌──────────────────────────────────────────────┐
│ Admin (Global Access)                        │
│ - Manage all organizations                   │
│ - Access all cases and data                  │
│ - Create/suspend Directors                   │
└──────────────────────────────────────────────┘
                    │
        ┌───────────┴───────────┐
        │                       │
┌───────▼──────────┐   ┌────────▼────────┐
│ Director         │   │ Support         │
│ (Org-Scoped)     │   │ (Read-Only)     │
│ - Manage cases   │   │ - View all data │
│ - Invite Family  │   │ - No mutations  │
│ - Assign Editors │   └─────────────────┘
└───────┬──────────┘
        │
    ┌───┴────┐
    │        │
┌───▼────┐ ┌─▼──────────────┐
│ Family │ │ Editor         │
│ (Case) │ │ (Assignment)   │
│ - View │ │ - Edit content │
│ - Edit │ │ - View assets  │
└────────┘ └────────────────┘
```

---

## Role Definitions

### 1. Admin
**Scope**: Global access across all organizations

**Permissions**:
- Full CRUD on all tables
- Create/suspend organizations
- Manage all users
- Access all audit logs
- Generate system-wide reports

**Use Cases**:
- Platform administrators
- System maintenance
- Customer onboarding
- Billing management

**Security Note**: Admin accounts should be heavily restricted and monitored.

---

### 2. Director
**Scope**: Organization-scoped access

**Permissions**:
- Full CRUD on cases within their org
- Create/invite Family users
- Assign Editors to cases
- View org-specific audit logs
- Manage org settings (via API)

**Use Cases**:
- Funeral home directors
- Case managers
- Organization administrators

**RLS Pattern**:
```sql
USING (
  auth.jwt() ->> 'role' = 'director' AND
  org_id = (auth.jwt() ->> 'org_id')::uuid
)
```

---

### 3. Family
**Scope**: Case-scoped access (only their assigned case)

**Permissions**:
- View their assigned case
- Fill out intake form (create/update)
- Upload photos/videos
- View submitted obituary
- No access to other cases

**Use Cases**:
- Family members of the deceased
- Submitting information for obituary

**RLS Pattern**:
```sql
USING (
  auth.jwt() ->> 'role' = 'family' AND
  assigned_family_user_id = auth.uid()
)
```

**Important**: Family users are invitation-only. Director creates case and generates login credentials.

---

### 4. Editor
**Scope**: Assignment-scoped access (only cases assigned to them)

**Permissions**:
- View assigned cases
- Read form submissions
- View uploaded assets
- Update case status (via API)
- No access to unassigned cases

**Use Cases**:
- Obituary writers
- Video editors
- Content creators

**RLS Pattern**:
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

### 5. Support
**Scope**: Global read-only access

**Permissions**:
- Read all tables
- No write/update/delete permissions
- Access audit logs for troubleshooting

**Use Cases**:
- Customer support agents
- Technical support
- Debugging production issues

**RLS Pattern**:
```sql
ON table FOR SELECT
USING (auth.jwt() ->> 'role' = 'support');
```

---

## RLS Policy Details

### Organizations Table

| Policy Name | Role | Operation | Description |
|------------|------|-----------|-------------|
| `Admins full access to organizations` | admin | ALL | Unrestricted access |
| `Directors read their organization` | director | SELECT | Read own org only |
| `Support read all organizations` | support | SELECT | Read-only monitoring |

**Security Guarantee**: Directors cannot see other organizations' data.

---

### Users Table

| Policy Name | Role | Operation | Description |
|------------|------|-----------|-------------|
| `Admins full access to users` | admin | ALL | Manage all accounts |
| `Directors manage users in their org` | director | ALL | Create Family accounts |
| `Users read their own profile` | all | SELECT | Self-service profile view |
| `Users update their own profile` | all | UPDATE | Self-service profile edit |
| `Support read all users` | support | SELECT | Troubleshooting |

**Security Guarantee**: Directors can only invite users to their own organization.

---

### Cases Table

| Policy Name | Role | Operation | Description |
|------------|------|-----------|-------------|
| `Admins full access to cases` | admin | ALL | Platform oversight |
| `Directors manage cases in their org` | director | ALL | Case creation/management |
| `Families read their assigned cases` | family | SELECT | View their case only |
| `Families update their assigned cases` | family | UPDATE | Limited field updates |
| `Editors read assigned cases` | editor | SELECT | View assigned work |
| `Editors update assigned cases` | editor | UPDATE | Content editing |
| `Support read all cases` | support | SELECT | Customer support |

**Security Guarantee**: Families cannot see other families' cases, even within the same org.

---

### Forms Table

| Policy Name | Role | Operation | Description |
|------------|------|-----------|-------------|
| `Admins full access to forms` | admin | ALL | Platform oversight |
| `Directors access forms in their org` | director | ALL | Review submissions |
| `Families manage their case forms` | family | ALL | Fill out intake form |
| `Editors read assigned case forms` | editor | SELECT | Reference material |
| `Support read all forms` | support | SELECT | Troubleshooting |

**Important**: Form submissions trigger `submitted_json` immutability and version history append.

---

### Assets Table

| Policy Name | Role | Operation | Description |
|------------|------|-----------|-------------|
| `Admins full access to assets` | admin | ALL | Platform oversight |
| `Directors manage assets in their org` | director | ALL | Review uploads |
| `Families manage their case assets` | family | ALL | Upload photos/videos |
| `Editors read assigned case assets` | editor | SELECT | Content creation |
| `Support read all assets` | support | SELECT | Troubleshooting |

**Storage Integration**: RLS policies also apply to Supabase Storage bucket access via `case-assets` bucket policies.

---

### Editor Assignments Table

| Policy Name | Role | Operation | Description |
|------------|------|-----------|-------------|
| `Admins full access to editor assignments` | admin | ALL | Platform oversight |
| `Directors manage assignments in their org` | director | ALL | Assign/unassign editors |
| `Editors read their own assignments` | editor | SELECT | View workload |
| `Support read all assignments` | support | SELECT | Troubleshooting |

**Note**: Editors cannot self-assign. Only Directors and Admins can create assignments.

---

### Events Table (Audit Log)

| Policy Name | Role | Operation | Description |
|------------|------|-----------|-------------|
| `Admins full access to events` | admin | ALL | Full audit access |
| `Directors read events in their org` | director | SELECT | Org-scoped audit trail |
| `Support read all events` | support | SELECT | Debugging |

**Security Guarantee**: Events table is append-only (enforced via RLS). No user can delete audit logs.

---

### Notifications Table

| Policy Name | Role | Operation | Description |
|------------|------|-----------|-------------|
| `Admins full access to notifications` | admin | ALL | Platform oversight |
| `Directors manage notifications in their org` | director | ALL | Communication mgmt |
| `Support read all notifications` | support | SELECT | Troubleshooting |

---

### Exports Table

| Policy Name | Role | Operation | Description |
|------------|------|-----------|-------------|
| `Admins full access to exports` | admin | ALL | Platform oversight |
| `Directors manage exports in their org` | director | ALL | Org data exports |
| `Users read their own exports` | all | SELECT | Download own exports |
| `Support read all exports` | support | SELECT | Troubleshooting |

---

## JWT Claims & Custom Metadata

### Standard Supabase Auth JWT

```json
{
  "sub": "user-uuid",
  "email": "user@example.com",
  "aud": "authenticated",
  "exp": 1728579600,
  "iat": 1728576000,
  "role": "authenticated"
}
```

### Custom Claims (Required for RLS)

Custom claims are added via database trigger or edge function on login:

```json
{
  "role": "director",
  "org_id": "00000000-0000-0000-0000-000000000001"
}
```

**Implementation**: See `handle_auth_user_login()` function in `003_functions_triggers.sql`.

---

## Testing RLS Policies

### Manual Testing with psql

```sql
-- Set JWT claims manually for testing
SET request.jwt.claims = '{
  "sub": "20000000-0000-0000-0000-000000000001",
  "role": "director",
  "org_id": "00000000-0000-0000-0000-000000000001"
}'::json;

-- Test: Director should only see their org's cases
SELECT * FROM cases;

-- Test: Director should NOT see other orgs' cases
SELECT * FROM cases WHERE org_id != '00000000-0000-0000-0000-000000000001';
-- Expected: 0 rows

-- Reset
RESET request.jwt.claims;
```

### Automated Testing

See `scripts/test-rls-policies.js` (to be created in Milestone 6) for automated RLS validation.

---

## Security Best Practices

### 1. Never Bypass RLS in Production

❌ **NEVER**:
```javascript
const { data } = await supabase
  .from('cases')
  .select()
  .eq('id', caseId); // Relies on RLS
```

✅ **ALWAYS** (in API routes):
```javascript
const { data, error } = await supabase
  .from('cases')
  .select()
  .eq('id', caseId)
  .eq('org_id', userOrgId) // Explicit filter
  .single();
```

### 2. Use Service Role Key Sparingly

Only use `SUPABASE_SERVICE_ROLE_KEY` for:
- Admin operations via API routes
- Background jobs (cron)
- System maintenance scripts

Never expose service role key in client-side code.

### 3. Audit Regular Reviews

- Weekly: Review `events` table for suspicious activity
- Monthly: Audit user access patterns
- Quarterly: Review and update RLS policies

### 4. API Layer Validation

RLS is defense-in-depth. Always validate in API layer too:

```javascript
// API route example
if (user.role === 'family' && case.assigned_family_user_id !== user.id) {
  return res.status(403).json({ error: 'Forbidden' });
}
```

---

## Common Attack Vectors & Mitigations

### 1. Cross-Tenant Data Access

**Attack**: Family user tries to access another family's case by guessing UUID.

**Mitigation**: RLS policy checks `assigned_family_user_id = auth.uid()`.

**Test**:
```sql
-- As Family User A
SELECT * FROM cases WHERE id = 'case-belonging-to-family-b';
-- Expected: 0 rows
```

---

### 2. Privilege Escalation

**Attack**: User modifies their own `role` field in `users` table.

**Mitigation**: RLS policy only allows users to UPDATE their profile, but `role` changes are restricted via API validation.

**Additional Protection**: Add CHECK constraint or trigger to prevent role changes via direct SQL.

---

### 3. Audit Log Tampering

**Attack**: Admin tries to delete evidence in `events` table.

**Mitigation**: `events` table has no DELETE policy (implicitly denied).

**Test**:
```sql
-- Even as Admin
DELETE FROM events WHERE id = 'some-event-id';
-- Expected: Permission denied
```

---

### 4. JWT Claim Manipulation

**Attack**: User modifies JWT to change `org_id`.

**Mitigation**: JWTs are cryptographically signed by Supabase. Tampering invalidates signature.

**Additional Protection**: Always verify JWT signature in API routes using `supabase.auth.getUser()`.

---

## Compliance Considerations

### GDPR Right to Erasure

When family requests data deletion:

1. Anonymize `users.email` and `users.metadata`
2. Remove `forms.submitted_json` PII
3. Delete `assets` from storage
4. Keep audit trail (legal basis: legitimate interest)

**Implementation**: Create `anonymize_user()` function (future milestone).

### HIPAA Compliance

If handling Protected Health Information (PHI):

1. Enable encryption at rest (Supabase default)
2. Enable encryption in transit (TLS only)
3. Audit all PHI access via `events` table
4. Implement automatic session timeout (30 minutes)
5. Require MFA for all users (Supabase Auth feature)

### SOC 2 Compliance

- RLS policies enforce access control (CC6.1)
- Audit logging via `events` table (CC7.2)
- Immutable audit trail (CC7.3)
- Automated backups (Supabase managed)

---

## Emergency Access Procedures

### Lost Admin Access

1. Use Supabase Dashboard to create new admin user
2. Update `users` table via SQL Editor
3. Document action in `events` table manually

### Compromised Account

1. Admin/Director immediately suspends user:
   ```sql
   UPDATE users SET status = 'suspended' WHERE id = 'compromised-user-id';
   ```
2. Review `events` table for unauthorized actions
3. Reset password via Supabase Auth
4. Re-enable account after verification

### RLS Policy Bug

If RLS policy is too permissive:

1. Immediately disable table access:
   ```sql
   REVOKE ALL ON table_name FROM authenticated;
   ```
2. Fix policy and test in staging
3. Apply fix to production
4. Re-enable access
5. Audit `events` for any unauthorized access during window

---

## Monitoring & Alerting

### Key Metrics to Track

1. **Failed RLS checks**: Indicates potential attack
2. **Cross-tenant query attempts**: Log via API layer
3. **Admin actions**: All admin operations should trigger alerts
4. **Unusual data exports**: Large exports outside business hours

### Recommended Alerts

- More than 5 failed auth attempts in 10 minutes
- Any `users.role` changes
- Any `organizations.status` changes to 'suspended'
- Exports larger than 10,000 rows

---

## Future Security Enhancements

1. **Field-Level Encryption**: Encrypt sensitive PII in `forms.submitted_json`
2. **Rate Limiting**: Per-user query limits via Supabase Edge Functions
3. **MFA Enforcement**: Require MFA for Director+ roles
4. **Session Recording**: Log all user sessions for compliance
5. **Automated Penetration Testing**: Regular security audits

---

**End of Security Documentation**

