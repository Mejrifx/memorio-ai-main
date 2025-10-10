# Memorio - AI-Powered Obituary & Tribute Platform

**Version:** 1.0.0  
**Status:** Backend Foundation Complete ✅

Memorio is a multi-tenant SaaS platform that helps funeral homes create personalized obituaries and tribute media through an intelligent intake system powered by N8N and AI.

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    MEMORIO PLATFORM                     │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Frontend (Existing)          Backend (NEW)            │
│  ├─ Family Intake Form    →   ├─ Supabase Database    │
│  ├─ Typewriter Display         ├─ Row Level Security   │
│  └─ N8N Webhook (preserved)    ├─ Auth & Invites      │
│                                 └─ Case Management      │
│                                                         │
│  Future Portals (Planned)                              │
│  ├─ Admin Dashboard                                    │
│  ├─ Director Dashboard                                 │
│  └─ Editor Workbench                                   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## 🎯 Current Status: Milestone 1 Complete

### ✅ What's Built

1. **Database Schema** (9 tables)
   - Organizations (funeral homes)
   - Users (all roles: admin, director, family, editor, support)
   - Cases (obituary projects)
   - Forms (intake data with version history)
   - Assets (photos/videos with deduplication)
   - Editor Assignments
   - Events (audit trail)
   - Notifications
   - Exports

2. **Security Infrastructure**
   - Row Level Security (RLS) policies for all tables
   - Multi-tenant data isolation
   - Role-based access control (RBAC)
   - JWT-based authentication
   - Immutable audit logging

3. **Automation**
   - Auto-updating timestamps
   - Audit event triggers
   - Form version history
   - Case status transitions

4. **Documentation**
   - Database schema reference
   - Security policies guide
   - Supabase setup instructions
   - Test account creation scripts

### 🔒 Security Model

**Role Hierarchy:**
- **Admin**: Global access to all organizations
- **Director**: Org-scoped access (manages cases, invites families)
- **Family**: Case-scoped access (fills intake form, uploads photos)
- **Editor**: Assignment-scoped access (creates obituaries)
- **Support**: Read-only global access

**Data Isolation:**
- Directors can only see their organization's data
- Families can only see their assigned case
- Editors can only see cases assigned to them
- All enforced at database level via RLS

## 📁 Project Structure

```
memorio-ai/
├── index.html                  # Family intake form (PRODUCTION - DO NOT MODIFY)
├── css/                        # Webflow-generated styles (preserved)
├── fonts/                      # Custom fonts
├── images/                     # Static assets
├── js/                         # Webflow scripts
│
├── supabase/                   # Database layer
│   ├── migrations/
│   │   ├── 001_initial_schema.sql
│   │   ├── 002_rls_policies.sql
│   │   ├── 003_functions_triggers.sql
│   │   └── 004_seed_data.sql
│   └── README.md
│
├── scripts/                    # Utility scripts
│   ├── create-test-accounts.js # Create test users
│   └── package.json
│
├── docs/                       # Documentation
│   ├── database-schema.md      # ERD and table reference
│   ├── security-policies.md    # RLS policy details
│   └── supabase-setup-guide.md # Setup instructions
│
├── .env.example                # Environment variables template
├── .gitignore
└── README.md                   # This file
```

## 🚀 Getting Started

### Prerequisites

- Node.js 18+
- Supabase account
- Supabase CLI (`npm install -g supabase`)

### 1. Clone Repository

```bash
git clone https://github.com/Mejrifx/memorio-ai-main.git
cd memorio-ai
```

### 2. Set Up Supabase

Follow the detailed guide in `docs/supabase-setup-guide.md`:

```bash
# Create Supabase project at https://supabase.com
# Copy credentials to .env
cp .env.example .env
# Edit .env with your credentials

# Apply database migrations
supabase link --project-ref your-project-ref
supabase db push
```

### 3. Create Test Accounts

```bash
cd scripts
npm install
node create-test-accounts.js
```

This creates test accounts for all roles:
- `admin@memorio.test`
- `director@testfuneralhome.com`
- `family@example.com`
- `editor@memorio.test`
- `support@memorio.test`

### 4. Verify Setup

```bash
# Check tables exist
supabase db pull

# Test RLS policies (see docs/security-policies.md)
```

## 📊 Database Schema

### Core Tables

| Table | Purpose | RLS Enforced |
|-------|---------|--------------|
| `organizations` | Funeral homes | ✅ Org-scoped |
| `users` | All user accounts | ✅ Role-based |
| `cases` | Obituary projects | ✅ Multi-tenant |
| `forms` | Family intake data | ✅ Case-scoped |
| `assets` | Photos/videos | ✅ Case-scoped |
| `editor_assignments` | Case assignments | ✅ Assignment-based |
| `events` | Audit log | ✅ Append-only |
| `notifications` | Email/SMS queue | ✅ Org-scoped |
| `exports` | Data exports | ✅ User-scoped |

See `docs/database-schema.md` for full ERD and details.

## 🔐 Security Highlights

- **Zero-Trust Architecture**: All data access verified at database level
- **RLS Enforcement**: 30+ policies protecting all tables
- **Audit Trail**: Immutable log of all sensitive actions
- **Encrypted Storage**: All data encrypted at rest and in transit
- **JWT-Based Auth**: Supabase Auth with custom claims

See `docs/security-policies.md` for penetration testing and compliance info.

## 🎨 Frontend (Existing - Preserved)

The family intake form at `index.html` is **production-stable** and integrated with N8N for AI-powered obituary generation. This form is preserved and will be enhanced (not replaced) in future milestones.

**Key Features:**
- Multi-step form with validation
- Month/day/year date pickers
- Country dropdown (US-first)
- UploadCare integration for photos
- N8N webhook for AI processing
- Typewriter effect for displaying results

**Critical Note:** The frontend form and N8N webhook are off-limits for backend work. All new features will extend around them, not through them.

## 🗺️ Roadmap

### Phase 1: Backend Foundation ✅ COMPLETE
- [x] Database schema design
- [x] RLS policies implementation
- [x] Audit logging system
- [x] Test account creation
- [x] Documentation

### Phase 2: Authentication & Invites (Next)
- [ ] Admin invite Director flow
- [ ] Director invite Family flow
- [ ] Magic link authentication
- [ ] Family onboarding UX
- [ ] Email templates

### Phase 3: Case Management APIs
- [ ] Director creates case
- [ ] Generate Family login
- [ ] Connect existing form to database
- [ ] Store form submissions
- [ ] Link assets to cases

### Phase 4: Admin Portal UI
- [ ] Organization management
- [ ] Director account creation
- [ ] System analytics
- [ ] Billing integration

### Phase 5: Director Portal UI
- [ ] Case dashboard
- [ ] Family invitation system
- [ ] Editor assignment
- [ ] Status tracking

### Phase 6: Editor Portal UI
- [ ] Case queue
- [ ] Form data view
- [ ] Asset gallery
- [ ] Delivery workflow

## 🧪 Testing

### Manual Testing

```bash
# Run local development server
python3 -m http.server 8000

# Visit http://localhost:8000
# Fill out form and test N8N integration
```

### RLS Testing

```sql
-- Test as director (in Supabase SQL Editor)
SET request.jwt.claims = '{"role": "director", "org_id": "00000000-0000-0000-0000-000000000001"}';
SELECT * FROM cases; -- Should only see org's cases

-- Test as family
SET request.jwt.claims = '{"role": "family", "sub": "30000000-0000-0000-0000-000000000001"}';
SELECT * FROM cases; -- Should only see assigned case
```

See `docs/security-policies.md` for comprehensive test scenarios.

## 📚 Documentation

| Document | Description |
|----------|-------------|
| `docs/database-schema.md` | Complete table reference and ERD |
| `docs/security-policies.md` | RLS policies and attack mitigation |
| `docs/supabase-setup-guide.md` | Step-by-step setup instructions |
| `supabase/README.md` | Migration management guide |

## 🛠️ Tech Stack

- **Frontend**: Vanilla JS, Webflow CSS, UploadCare
- **Backend**: Supabase (PostgreSQL + Auth + Storage)
- **AI/Automation**: N8N workflows
- **Deployment**: Netlify (frontend), Supabase (backend)
- **Version Control**: Git + GitHub

## 🤝 Contributing

This is a private commercial project. Internal team members should follow:

1. Never modify `index.html` or N8N webhook integration
2. All database changes via migrations (never direct edits)
3. Test RLS policies before pushing
4. Update documentation with schema changes
5. Use conventional commits

## 📧 Support

For questions or issues:
- **Technical**: Review `docs/` directory first
- **Database**: Check `docs/database-schema.md`
- **Security**: See `docs/security-policies.md`
- **Setup**: Follow `docs/supabase-setup-guide.md`

## 📄 License

Proprietary - All Rights Reserved

---

**Built with ❤️ for funeral homes helping families honor their loved ones.**
