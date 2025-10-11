# Memorio - Funeral Home SaaS Platform

**Status:** Backend Complete ✅ | Frontend Portals Next 🚧  
**Version:** Milestone 2 - Authentication & Invite System

---

## 🎯 **What This Is**

Memorio is a private, role-gated SaaS platform for funeral homes to manage obituary creation and tribute media production. The platform features:

- **Admin Portal**: Manage organizations and invite Directors
- **Director Portal**: Create cases and invite Families  
- **Family Portal**: Complete tribute intake forms
- **Editor Portal**: Process and deliver tributes

---

## 🏗️ **Architecture**

### **Backend (Complete)**
- ✅ **Supabase Database**: 9 tables with multi-tenant RLS policies
- ✅ **Edge Functions**: 3 APIs for user invitations and case management
- ✅ **Authentication**: Role-based access control (Admin → Director → Family)
- ✅ **Storage**: Secure file uploads with RLS policies
- ✅ **Audit Logging**: Complete action tracking

### **Frontend (In Progress)**
- ✅ **Family Intake Form**: Working with N8N webhook integration
- 🚧 **Admin Portal**: Invite Directors (Next)
- 🚧 **Director Portal**: Create Cases & Invite Families (Next)
- 🚧 **Form Integration**: Connect existing form to database (Next)

---

## 📁 **Project Structure**

```
memorio-ai/
├── index.html                 # Family intake form (preserved)
├── css/                       # Memorio brand styling
├── fonts/                     # Dosis font family
├── images/                    # Logo and assets
├── js/                        # Webflow scripts
├── netlify.toml              # Deployment config
├── .env                      # Supabase credentials
├── supabase/
│   ├── functions/            # Edge Functions (deployed)
│   │   ├── invite-director/  # Admin → Director invites
│   │   ├── invite-family/    # Director → Family invites
│   │   ├── create-case/      # Director creates cases
│   │   └── _shared/          # Shared utilities
│   └── migrations/           # Database schema (deployed)
├── scripts/
│   └── create-test-accounts.js # Test user creation
└── docs/
    ├── database-schema.md    # Database documentation
    └── security-policies.md # RLS policy documentation
```

---

## 🚀 **Live APIs**

Your Edge Functions are deployed and accessible at:

- **invite-director**: `https://gkabtvqwwuvigcdubwyv.supabase.co/functions/v1/invite-director`
- **invite-family**: `https://gkabtvqwwuvigcdubwyv.supabase.co/functions/v1/invite-family`
- **create-case**: `https://gkabtvqwwuvigcdubwyv.supabase.co/functions/v1/create-case`

---

## 🎨 **Design System**

All UIs follow the Memorio brand:
- **Colors**: Warm cream (`#f4e8de`), Light peach (`#fff3e9`), Dark slate (`#32343a`)
- **Font**: Dosis Variable Weight (200-800)
- **Components**: Rounded buttons (60px), card borders (20px), form styling

---

## 🔐 **Security**

- **Multi-tenant RLS**: Directors only see their org data
- **Role-based access**: Families only see assigned cases
- **Audit logging**: All actions tracked immutably
- **Invitation-only**: No public registration

---

## 📊 **Current Status**

### ✅ **Completed (Milestone 1 & 2 Backend)**
- Database schema with 9 tables
- RLS policies for multi-tenant security
- Edge Functions for authentication & invites
- Email templates (Memorio-branded)
- Test accounts and sample data
- Complete documentation

### 🚧 **Next (Milestone 2 Frontend)**
- Admin Portal UI (login + invite Director)
- Director Portal UI (login + create case + invite Family)
- Connect existing form to database
- Test complete invite flow

---

## 🧪 **Test Accounts**

Ready-to-use test accounts:
- **Admin**: `admin@memorio.test` / `TestAdmin123!`
- **Director**: `director@testfuneralhome.com` / `TestDirector123!`
- **Family**: `family@example.com` / `TestFamily123!`
- **Editor**: `editor@memorio.test` / `TestEditor123!`
- **Support**: `support@memorio.test` / `TestSupport123!`

---

## 🚀 **Next Steps**

1. **Build Admin Portal** - UI for admins to invite directors
2. **Build Director Portal** - UI for directors to manage cases
3. **Connect Form to Database** - Save family submissions
4. **Test Complete Flow** - End-to-end invite system

---

**Milestone 2 Backend: ✅ Complete**  
**Ready for Frontend Development** 🚀

