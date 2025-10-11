# Milestone 2: Authentication & Invite System

**Status:** 🚧 In Progress  
**Start Date:** October 11, 2025  
**Estimated Completion:** 2-3 days

---

## 🎨 Design System (Memorio Brand)

### Color Palette
- **Primary Background**: `#f4e8de` (Warm cream)
- **Secondary Background**: `#fff3e9` (Light peach)
- **Primary Text**: `#32343a` (Dark slate)
- **Secondary Text**: `#33333373` (Gray, 45% opacity)
- **Accent Blue**: `#6ca7d3` (Sky blue - hover states)
- **Border**: `#436481` (Teal blue - form borders)
- **Button Background**: `#32343a` (Dark slate)
- **Button Text**: `#f2eadd` (Off-white)

### Typography
- **Primary Font**: `Dosis Variablefont Wght` (200-800 weight range)
- **Fallback**: Arial, sans-serif
- **Body Size**: 14px / 20px line-height
- **Headings**: Larger sizes with same font family

### UI Components
- **Border Radius**: 20px (cards/bubbles), 60px (buttons), 5px (inputs)
- **Button Style**: Uppercase, 2px letter-spacing, rounded
- **Shadows**: `0 2px 8px -2px #0003` (subtle)
- **Borders**: 0.5px solid (inputs), 3px solid (form boxes)

---

## 📋 Implementation Plan

### Phase 1: Backend - Edge Functions & APIs (Day 1)

#### 1.1 Create Edge Functions Structure
```
supabase/functions/
├── invite-director/
│   └── index.ts
├── invite-family/
│   └── index.ts
├── create-case/
│   └── index.ts
└── _shared/
    ├── supabase-client.ts
    ├── email-templates.ts
    └── types.ts
```

#### 1.2 Invite Director API
**Endpoint**: `/functions/v1/invite-director`

**Functionality**:
- Admin creates Director account
- Validates email uniqueness
- Creates Supabase Auth user
- Inserts user metadata in `users` table
- Generates temporary password
- Sends invitation email via Supabase
- Logs action in `events` table

**Request Body**:
```typescript
{
  email: string;
  name: string;
  org_id: string;
  phone?: string;
}
```

**Response**:
```typescript
{
  success: boolean;
  user_id: string;
  temp_password: string;
  message: string;
}
```

#### 1.3 Invite Family API
**Endpoint**: `/functions/v1/invite-family`

**Functionality**:
- Director creates Family account
- Links Family to specific case
- Creates Supabase Auth user
- Inserts user metadata with case assignment
- Generates magic link
- Sends invitation email
- Updates case status to `waiting_on_family`
- Logs action in `events` table

**Request Body**:
```typescript
{
  email: string;
  name: string;
  case_id: string;
  phone?: string;
}
```

**Response**:
```typescript
{
  success: boolean;
  user_id: string;
  magic_link: string;
  message: string;
}
```

#### 1.4 Create Case API
**Endpoint**: `/functions/v1/create-case`

**Functionality**:
- Director creates new case
- Inserts case record
- Creates empty form record
- Returns case_id for Family invitation
- Logs action in `events` table

**Request Body**:
```typescript
{
  deceased_name: string;
  service_date?: string;
  service_location?: string;
  metadata?: object;
}
```

**Response**:
```typescript
{
  success: boolean;
  case_id: string;
  message: string;
}
```

---

### Phase 2: Email Templates (Day 1)

#### 2.1 Configure Supabase Email Service
- Update email templates in Supabase Dashboard
- Set sender name: "Memorio"
- Set sender email: `noreply@memorio.ai`
- Add logo and branding

#### 2.2 Director Invitation Email
**Subject**: Welcome to Memorio - Your Director Account

**Template**:
```html
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: 'Dosis', Arial, sans-serif; background-color: #f4e8de; }
    .container { max-width: 600px; margin: 0 auto; background-color: #fff3e9; border-radius: 20px; padding: 40px; }
    .header { text-align: center; color: #32343a; }
    .button { background-color: #32343a; color: #f2eadd; padding: 15px 30px; border-radius: 60px; text-decoration: none; display: inline-block; }
  </style>
</head>
<body>
  <div class="container">
    <h1 class="header">Welcome to Memorio</h1>
    <p>You've been invited to manage funeral home cases on Memorio.</p>
    <p><strong>Email:</strong> {{ .Email }}</p>
    <p><strong>Temporary Password:</strong> {{ .TempPassword }}</p>
    <p>Please login and change your password immediately.</p>
    <a href="https://memorio.ai/director/login" class="button">Login Now</a>
  </div>
</body>
</html>
```

#### 2.3 Family Invitation Email
**Subject**: Create a Tribute for {{ .DeceasedName }}

**Template**:
```html
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: 'Dosis', Arial, sans-serif; background-color: #f4e8de; }
    .container { max-width: 600px; margin: 0 auto; background-color: #fff3e9; border-radius: 20px; padding: 40px; }
    .header { text-align: center; color: #32343a; }
    .button { background-color: #32343a; color: #f2eadd; padding: 15px 30px; border-radius: 60px; text-decoration: none; display: inline-block; }
  </style>
</head>
<body>
  <div class="container">
    <h1 class="header">Memorial Tribute Invitation</h1>
    <p>You've been invited to create a tribute for {{ .DeceasedName }}.</p>
    <p>Click the button below to begin the form. This link is secure and only accessible to you.</p>
    <a href="{{ .MagicLink }}" class="button">Start Creating Tribute</a>
  </div>
</body>
</html>
```

---

### Phase 3: Portal UIs (Day 2-3)

#### 3.1 Admin Portal (`admin/index.html`)
**Features**:
- Login page (uses existing design system)
- Dashboard with organization list
- "Invite Director" button
- Modal/form to enter Director details
- Success confirmation

**UI Components**:
- Nav with Memorio logo
- Form styled like existing intake form
- Buttons with hover effects matching brand
- Background: `#f4e8de`

#### 3.2 Director Portal (`director/index.html`)
**Features**:
- Login page
- Dashboard with case list
- "Create New Case" button
- "Invite Family" button (per case)
- Case status tracking

**UI Components**:
- Same nav structure
- Table/cards for case list
- Form modals for case creation
- Status badges matching color scheme

#### 3.3 Login Pages
**Features**:
- Email + password input
- "Forgot Password?" link
- Form validation
- Error messages

**Design**:
- Centered form box (like existing intake form)
- Background: `#f4e8de`
- Form background: `#fff3e9`
- Border: `3px solid #436481`

---

### Phase 4: Authentication Flows (Day 2-3)

#### 4.1 Login Flow
1. User enters email/password
2. Frontend calls `supabase.auth.signInWithPassword()`
3. Supabase validates credentials
4. Returns JWT with custom claims (role, org_id)
5. Redirect to appropriate portal based on role

#### 4.2 Magic Link Flow (Family)
1. Family clicks magic link from email
2. Supabase Auth validates token
3. Auto-login user
4. Redirect to intake form with case pre-populated

#### 4.3 Password Reset Flow
1. User clicks "Forgot Password?"
2. Enter email
3. Frontend calls `supabase.auth.resetPasswordForEmail()`
4. Supabase sends reset email
5. User clicks link, enters new password
6. Redirect to login

---

### Phase 5: Connect Existing Form to Database (Day 3)

#### 5.1 Modify `index.html` Form Submission
**Current Flow**:
```
Form Submit → N8N Webhook → AI Processing → Display Result
```

**New Flow**:
```
Form Submit → Save to Database → N8N Webhook → AI Processing → Display Result
                    ↓
              Update Case Status
```

**Changes**:
- Add Supabase client to `index.html`
- On form submit, save `draft_json` to `forms` table
- On N8N success, update `submitted_json` and `submitted_at`
- Update case status to `submitted`
- Create asset records for uploaded files

#### 5.2 Database Integration
```javascript
// Add to index.html form submission
async function saveFormToDatabase(formData, caseId) {
  const { data, error } = await supabase
    .from('forms')
    .upsert({
      case_id: caseId,
      draft_json: formData,
      json_schema_version: 'v1'
    });
  
  if (error) console.error('Error saving form:', error);
  return data;
}

// After N8N success
async function markFormSubmitted(formId, formData) {
  const { data, error } = await supabase
    .from('forms')
    .update({
      submitted_json: formData,
      submitted_at: new Date().toISOString()
    })
    .eq('id', formId);
  
  // Update case status
  await supabase
    .from('cases')
    .update({ status: 'submitted' })
    .eq('id', caseId);
}
```

---

## 🔒 Security Considerations

### JWT Custom Claims
Set custom claims on login:
```typescript
{
  role: 'director',
  org_id: 'uuid',
  case_id: 'uuid' // (for family users)
}
```

### RLS Enforcement
- All API calls go through RLS policies
- Edge Functions use service role key only for auth operations
- Frontend uses anon key with user JWT

### Email Security
- Magic links expire after 24 hours
- Temporary passwords must be changed on first login
- Rate limiting on invite endpoints (10 per hour per user)

---

## 📊 Success Metrics

- [ ] Admin can invite Directors
- [ ] Directors can create cases
- [ ] Directors can invite Families
- [ ] Families receive magic link emails
- [ ] Family can access form via magic link
- [ ] Form submission saves to database
- [ ] N8N webhook still functions
- [ ] Case status updates automatically
- [ ] All UIs match Memorio design system
- [ ] RLS policies enforce access control

---

## 🚀 Deployment Checklist

- [ ] Deploy Edge Functions to Supabase
- [ ] Configure email templates
- [ ] Upload portal UIs to Netlify
- [ ] Test invite flow end-to-end
- [ ] Verify database integration
- [ ] Test RLS policies with real users
- [ ] Update documentation

---

**Next Milestone**: Case Management & Editor Portal

