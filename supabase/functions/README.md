# Memorio Edge Functions

Supabase Edge Functions for the Memorio platform authentication and invite system.

## Functions

### 1. `invite-director`
Allows Admins to invite Directors to manage funeral homes.

**Endpoint**: `POST /functions/v1/invite-director`

**Auth**: Requires Admin role

**Request Body**:
```json
{
  "email": "director@funeralhome.com",
  "name": "John Director",
  "org_id": "uuid",
  "phone": "+1-555-0123" // optional
}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "user_id": "uuid",
    "temp_password": "TempPass123!",
    "email": "director@funeralhome.com"
  },
  "message": "Director invitation sent to director@funeralhome.com"
}
```

---

### 2. `invite-family`
Allows Directors to invite Family members to create tributes for specific cases.

**Endpoint**: `POST /functions/v1/invite-family`

**Auth**: Requires Director role

**Request Body**:
```json
{
  "email": "family@example.com",
  "name": "Jane Family",
  "case_id": "uuid",
  "phone": "+1-555-0456" // optional
}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "user_id": "uuid",
    "magic_link": "https://memorio.ai/?token=...",
    "email": "family@example.com",
    "case_id": "uuid"
  },
  "message": "Family invitation sent to family@example.com"
}
```

---

### 3. `create-case`
Allows Directors to create new cases for deceased individuals.

**Endpoint**: `POST /functions/v1/create-case`

**Auth**: Requires Director role

**Request Body**:
```json
{
  "deceased_name": "John Doe",
  "service_date": "2025-10-15", // optional
  "service_location": "Memorial Chapel", // optional
  "metadata": {} // optional
}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "case_id": "uuid",
    "deceased_name": "John Doe",
    "status": "created",
    "created_at": "2025-10-11T..."
  },
  "message": "Case created successfully for John Doe"
}
```

---

## Deployment

### Prerequisites
- Supabase CLI installed: `npm install -g supabase`
- Supabase project linked: `supabase link --project-ref your-project-ref`

### Deploy All Functions
```bash
# Deploy all functions
supabase functions deploy invite-director
supabase functions deploy invite-family
supabase functions deploy create-case
```

### Deploy Individual Function
```bash
supabase functions deploy invite-director
```

### Set Environment Variables
Functions automatically have access to:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`

No additional configuration needed.

---

## Local Development

### Start Functions Locally
```bash
supabase start
supabase functions serve
```

Functions will be available at:
- `http://localhost:54321/functions/v1/invite-director`
- `http://localhost:54321/functions/v1/invite-family`
- `http://localhost:54321/functions/v1/create-case`

### Test with curl
```bash
# Get auth token first
curl -X POST https://your-project.supabase.co/auth/v1/token \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@memorio.test","password":"TestAdmin123!"}'

# Test invite-director
curl -X POST http://localhost:54321/functions/v1/invite-director \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "newdirector@test.com",
    "name": "New Director",
    "org_id": "00000000-0000-0000-0000-000000000001"
  }'
```

---

## Security

- All functions verify authentication via JWT
- Role-based access control enforced
- RLS policies apply to all database operations
- Audit events logged for all actions
- Rate limiting recommended (configure in Supabase Dashboard)

---

## Error Handling

All functions return consistent error responses:
```json
{
  "success": false,
  "error": "Error message here"
}
```

HTTP Status Codes:
- `200`: Success
- `400`: Bad request (missing fields)
- `401`: Unauthorized (no auth token)
- `403`: Forbidden (wrong role)
- `404`: Not found (resource doesn't exist)
- `500`: Internal server error

---

## Monitoring

View function logs in Supabase Dashboard:
1. Go to Edge Functions
2. Select function
3. Click "Logs" tab

Or via CLI:
```bash
supabase functions logs invite-director
```

---

## Next Steps

1. Deploy functions to Supabase
2. Configure email templates in Supabase Dashboard
3. Build Admin/Director portals to call these APIs
4. Test invite flow end-to-end

