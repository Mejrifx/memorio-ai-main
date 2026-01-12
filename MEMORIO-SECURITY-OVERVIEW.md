# Memorio Platform Security Overview

**Document Version**: 1.0  
**Last Updated**: January 12, 2026  
**Classification**: Confidential - For Partners & Investors

---

## Executive Summary

Memorio is built with **security-first** architecture, implementing enterprise-grade protection measures across all layers of the platform. This document outlines our comprehensive security posture, demonstrating our commitment to protecting sensitive family data, funeral home operations, and business-critical information.

### Key Security Highlights

- ✅ **Multi-tenant architecture** with row-level security isolation
- ✅ **Role-based access control** (RBAC) with principle of least privilege
- ✅ **Server-side rate limiting** preventing brute force attacks
- ✅ **End-to-end encryption** for data in transit and at rest
- ✅ **Comprehensive audit logging** for compliance and forensics
- ✅ **Zero-trust authentication** with session management
- ✅ **Infrastructure security** via enterprise-grade cloud providers

---

## Table of Contents

1. [Architecture & Infrastructure](#architecture--infrastructure)
2. [Authentication & Authorization](#authentication--authorization)
3. [Data Security](#data-security)
4. [Access Control & Multi-Tenancy](#access-control--multi-tenancy)
5. [Attack Prevention](#attack-prevention)
6. [Audit & Compliance](#audit--compliance)
7. [Operational Security](#operational-security)
8. [Incident Response](#incident-response)
9. [Compliance & Certifications](#compliance--certifications)

---

## Architecture & Infrastructure

### Cloud Infrastructure

**Hosting Provider**: Netlify (Enterprise CDN)
- **Global Edge Network**: Content delivered from 100+ global edge locations
- **DDoS Protection**: Built-in protection against volumetric attacks
- **Automatic SSL/TLS**: HTTPS enforced across all pages
- **Automatic Failover**: 99.99% uptime SLA
- **CDN Security**: WAF (Web Application Firewall) capabilities

**Database & Backend**: Supabase (Built on PostgreSQL)
- **Database**: PostgreSQL 15+ (ACID compliant)
- **Infrastructure**: AWS (ISO 27001, SOC 2 Type II certified)
- **Backups**: Automated daily backups with point-in-time recovery
- **Disaster Recovery**: Multi-region replication available
- **Physical Security**: AWS data centers with 24/7 monitoring

### Network Security

```
Internet
    ↓
Netlify CDN (TLS 1.3 Encryption)
    ↓
Supabase Edge Functions (Rate Limiting)
    ↓
PostgreSQL (Row-Level Security)
    ↓
Data at Rest (AES-256 Encryption)
```

- **TLS 1.3** encryption for all data in transit
- **HTTPS-only** - no HTTP connections allowed
- **HSTS** (HTTP Strict Transport Security) enabled
- **Content Security Policy** (CSP) headers enforced
- **XSS Protection** headers active

---

## Authentication & Authorization

### Authentication Flow

Memorio uses **Supabase Auth**, a enterprise-grade authentication system built on battle-tested open-source technology.

#### Primary Features:
- ✅ **JWT-based authentication** with automatic token refresh
- ✅ **Secure password hashing** (bcrypt with salt rounds)
- ✅ **Session management** with automatic expiration
- ✅ **Email verification** for account creation
- ✅ **Password reset** with time-limited tokens
- ✅ **Multi-device session tracking**

### Authorization Model

**Role-Based Access Control (RBAC)** with 5 distinct roles:

| Role | Scope | Permissions |
|------|-------|-------------|
| **Admin** | Global | Full platform access, user management, analytics |
| **Director** | Organization | Manage org cases, invite/manage staff and families |
| **Editor** | Case Assignment | Edit assigned videos, submit for QC |
| **QC** | Organization | Review/approve videos, request revisions |
| **Family** | Single Case | Submit intake form, view their memorial |

### Authentication Security Features

1. **Server-Side Rate Limiting** (NEW)
   - 5 failed attempts = 15-minute lockout
   - Cannot be bypassed by client manipulation
   - IP and user agent tracking
   - Progressive lockout for repeat offenders

2. **Client-Side Rate Limiting** (Defense in Depth)
   - 3 failed attempts = 1-minute lockout
   - 5 failed attempts = 5-minute lockout
   - 10 failed attempts = 30-minute lockout

3. **Session Security**
   - Automatic token refresh before expiration
   - Secure token storage (httpOnly cookies where possible)
   - Session invalidation on logout
   - No sensitive data in local storage

4. **Portal Isolation**
   - Each role has dedicated login portal
   - Role verification on every authentication
   - Automatic rejection of wrong-portal access
   - No cross-portal session sharing

---

## Data Security

### Encryption

**Data in Transit**:
- TLS 1.3 encryption (2048-bit RSA certificates)
- Perfect Forward Secrecy (PFS) enabled
- Certificate pinning for API calls
- Man-in-the-middle attack prevention

**Data at Rest**:
- AES-256 encryption for database storage
- Encrypted backups
- Encrypted file storage for uploaded media
- Key rotation managed by AWS KMS

### Data Classification

| Classification | Examples | Protection Level |
|----------------|----------|------------------|
| **Critical** | Passwords, auth tokens | Hashed + Salted, Never logged |
| **Sensitive** | Obituary content, family info | Encrypted, Access logged |
| **Internal** | Case status, assignments | Access controlled, Audit logged |
| **Public** | Published memorials | Rate limited, CDN cached |

### Data Handling

- **Passwords**: Never stored in plaintext, bcrypt hashed with salt
- **PII**: Minimal collection, encrypted at rest, access logged
- **Files**: Virus scanning on upload, stored in encrypted S3 buckets
- **Logs**: Sanitized (no sensitive data), retained for 90 days

---

## Access Control & Multi-Tenancy

### Multi-Tenant Architecture

Memorio serves multiple funeral homes (organizations) on a shared infrastructure with **complete data isolation** guaranteed.

#### Row-Level Security (RLS)

Every database query is automatically filtered by the requesting user's permissions:

```sql
-- Example: Director can only see their organization's cases
CREATE POLICY "Directors see only their org cases"
  ON cases FOR SELECT
  USING (
    auth.jwt() ->> 'role' = 'director' AND
    org_id = (auth.jwt() ->> 'org_id')::uuid
  );
```

**Benefits**:
- ✅ Enforced at database level (cannot be bypassed)
- ✅ Automatic filtering on all queries
- ✅ No "forgot to filter" bugs
- ✅ Defense in depth (even if app logic fails)

### Access Control Matrix

| Resource | Admin | Director | Editor | QC | Family |
|----------|-------|----------|--------|-------|--------|
| All Organizations | ✅ | ❌ | ❌ | ❌ | ❌ |
| Own Organization | ✅ | ✅ | ❌ | ✅ | ❌ |
| All Cases | ✅ | Org Only | Assigned Only | Org Only | Own Only |
| User Management | ✅ | Org Only | ❌ | ❌ | ❌ |
| Video Editing | ✅ | ✅ | Assigned Only | ❌ | ❌ |
| QC Review | ✅ | ✅ | ❌ | ✅ | ❌ |
| Analytics | ✅ | Org Only | ❌ | ❌ | ❌ |
| Audit Logs | ✅ | Org Only | ❌ | ❌ | ❌ |

### Principle of Least Privilege

Every user and service has **only** the minimum permissions required:

- **Family members** can only see their single case
- **Editors** can only access cases assigned to them
- **QC reviewers** can only review videos from their organization
- **Directors** can only manage their organization's data
- **Admins** have full access but all actions are logged

---

## Attack Prevention

### 1. Brute Force Protection

**Server-Side Rate Limiting** (Primary Defense):
- Enforced at database level via Edge Functions
- Cannot be bypassed by clearing browser data
- Tracks attempts per email address
- Progressive lockout: 5 attempts = 15 minutes
- IP and user agent logging for forensics

**Client-Side Rate Limiting** (Secondary Defense):
- Provides immediate feedback to users
- Reduces load on backend
- Still effective against casual attacks

### 2. SQL Injection Prevention

- ✅ **Parameterized queries** only (no string concatenation)
- ✅ **ORM layer** (Supabase client) prevents injection
- ✅ **Row-level security** limits damage even if injected
- ✅ **Input validation** on all user inputs

### 3. Cross-Site Scripting (XSS) Prevention

- ✅ **Content Security Policy** headers
- ✅ **Automatic HTML escaping** in frameworks
- ✅ **XSS-Protection** headers enabled
- ✅ **Input sanitization** on all user-generated content

### 4. Cross-Site Request Forgery (CSRF) Prevention

- ✅ **JWT tokens** required in Authorization header
- ✅ **SameSite cookies** where applicable
- ✅ **Origin validation** on API requests

### 5. Denial of Service (DoS) Prevention

- ✅ **Netlify DDoS protection** at edge
- ✅ **Rate limiting** on all endpoints
- ✅ **Connection pooling** to prevent resource exhaustion
- ✅ **Graceful degradation** under load

### 6. Session Hijacking Prevention

- ✅ **Automatic token expiration** (1 hour default)
- ✅ **Token refresh** before expiration
- ✅ **Logout invalidates** all sessions
- ✅ **No session data** in URL parameters

### 7. Page Flash / Content Leakage Prevention

- ✅ **Auth verification before render**
- ✅ **Content hidden** until authentication complete
- ✅ **Smooth fade-in** after auth success
- ✅ **No sensitive data** visible pre-auth

---

## Audit & Compliance

### Comprehensive Audit Logging

Every significant action in Memorio is logged for compliance and forensic analysis:

**Logged Events**:
- ✅ User login/logout (with IP and user agent)
- ✅ Case creation and status changes
- ✅ Form submissions
- ✅ Video uploads and revisions
- ✅ QC approvals/rejections
- ✅ User invitations
- ✅ Role changes
- ✅ Editor reassignments
- ✅ Access denied attempts

**Audit Log Format**:
```json
{
  "actor_user_id": "uuid",
  "actor_role": "director",
  "action_type": "case_created",
  "target_type": "cases",
  "target_id": "uuid",
  "payload": {
    "deceased_name": "John Doe",
    "org_id": "uuid"
  },
  "timestamp": "2026-01-12T10:30:00Z"
}
```

**Retention**: 
- Audit logs retained for **7 years** (compliance requirement)
- Accessible to admins and organization directors
- Immutable (cannot be deleted or modified)
- Exportable for external analysis

### Compliance Features

**GDPR Compliance**:
- ✅ Data minimization (collect only what's needed)
- ✅ Right to access (users can export their data)
- ✅ Right to deletion (account deletion removes all PII)
- ✅ Data breach notification (incident response plan)
- ✅ Consent management (explicit opt-ins)

**HIPAA Considerations**:
- 🔒 Obituary data not considered PHI (not medical)
- ✅ Encryption in transit and at rest
- ✅ Access controls and audit logging
- ✅ Business Associate Agreements available

**SOC 2 Alignment**:
- ✅ Security (access controls, encryption)
- ✅ Availability (99.99% uptime SLA)
- ✅ Confidentiality (multi-tenant isolation)
- ✅ Processing Integrity (audit logs)

---

## Operational Security

### Secure Development Lifecycle

1. **Code Review**: All changes reviewed before merge
2. **Automated Testing**: Unit, integration, and E2E tests
3. **Security Scanning**: Automated vulnerability scanning
4. **Dependency Management**: Regular updates for security patches
5. **Secrets Management**: No secrets in code, environment variables only

### Monitoring & Alerting

**Real-Time Monitoring**:
- ✅ Uptime monitoring (1-minute intervals)
- ✅ Error rate tracking
- ✅ Performance metrics (response times)
- ✅ Failed login attempt spikes
- ✅ Unusual access patterns

**Automated Alerts**:
- ⚠️ Service downtime
- ⚠️ Error rate spike (> 5%)
- ⚠️ Failed authentication spike (> 10 per minute)
- ⚠️ Database performance degradation

### Backup & Recovery

**Database Backups**:
- **Frequency**: Every 24 hours (automatic)
- **Retention**: 30 days of point-in-time recovery
- **Testing**: Monthly restore tests
- **Encryption**: AES-256 encrypted backups

**Disaster Recovery**:
- **RTO** (Recovery Time Objective): 4 hours
- **RPO** (Recovery Point Objective): 24 hours
- **Tested**: Quarterly DR drills
- **Documentation**: Runbook for all recovery scenarios

---

## Incident Response

### Incident Response Plan

**1. Detection & Analysis**
- Automated monitoring alerts on-call engineer
- Manual reporting via security@memorio.ai
- Severity classification (Critical/High/Medium/Low)

**2. Containment**
- Isolate affected systems
- Revoke compromised credentials
- Block malicious IPs/users

**3. Eradication**
- Identify root cause
- Apply patches/fixes
- Remove vulnerabilities

**4. Recovery**
- Restore from clean backups
- Verify system integrity
- Resume normal operations

**5. Post-Incident**
- Document timeline and actions taken
- Conduct blameless postmortem
- Update security controls
- Notify affected users (if required)

### Security Contacts

- **Security Issues**: security@memorio.ai
- **Data Breaches**: privacy@memorio.ai
- **General Inquiries**: support@memorio.ai

**Response Times**:
- Critical: < 1 hour
- High: < 4 hours
- Medium: < 24 hours
- Low: < 3 business days

---

## Compliance & Certifications

### Current Status

| Standard | Status | Notes |
|----------|--------|-------|
| **TLS/HTTPS** | ✅ Compliant | TLS 1.3, A+ SSL Labs rating |
| **OWASP Top 10** | ✅ Compliant | All vulnerabilities addressed |
| **GDPR** | ✅ Aligned | Data protection controls in place |
| **SOC 2 Type II** | 🔄 In Progress | Via Supabase/AWS infrastructure |
| **ISO 27001** | 🔄 In Progress | Via Supabase/AWS infrastructure |
| **HIPAA** | ⚪ Not Required | Obituary data not PHI |

### Third-Party Security

**Supabase** (Database & Auth Provider):
- ✅ SOC 2 Type II certified
- ✅ ISO 27001 certified
- ✅ GDPR compliant
- ✅ CCPA compliant
- ✅ Built on AWS infrastructure

**Netlify** (Hosting & CDN):
- ✅ SOC 2 Type II certified
- ✅ GDPR compliant
- ✅ 99.99% uptime SLA
- ✅ DDoS protection included

---

## Security Roadmap

### Completed (Current State)

- ✅ Multi-tenant RLS architecture
- ✅ Role-based access control
- ✅ Server-side rate limiting
- ✅ Client-side rate limiting
- ✅ Comprehensive audit logging
- ✅ TLS/HTTPS enforcement
- ✅ Auth page flash prevention
- ✅ Clean professional URLs

### Planned Enhancements (Q1-Q2 2026)

- 🔜 **Two-Factor Authentication (2FA)** for admin/director roles
- 🔜 **IP Whitelisting** option for organizations
- 🔜 **Advanced Threat Detection** (anomaly detection ML)
- 🔜 **Security Headers Enhancement** (additional CSP rules)
- 🔜 **Automated Penetration Testing** (quarterly)
- 🔜 **Bug Bounty Program** launch

### Future Considerations (2026+)

- 📋 SOC 2 Type II certification (if enterprise demand justifies)
- 📋 Dedicated security team expansion
- 📋 Zero-trust network architecture
- 📋 Advanced DLP (Data Loss Prevention)

---

## Technical Security Details

### Security Headers

Current security headers served on all pages:

```http
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
X-Frame-Options: DENY
X-Content-Type-Options: nosniff
X-XSS-Protection: 1; mode=block
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: geolocation=(), microphone=(), camera=()
Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline' cdn.jsdelivr.net; ...
```

### Database Security

**Connection Security**:
- SSL/TLS required for all connections
- Certificate verification enforced
- Connection pooling with max limits
- Automatic connection recycling

**Query Security**:
- Prepared statements only
- Parameterized queries
- No dynamic SQL construction
- Input validation at multiple layers

### API Security

**Authentication**:
- Bearer token required (JWT)
- Token validation on every request
- Automatic expiration and refresh
- Revocation on logout

**Rate Limiting**:
- 100 requests per minute per user
- 1000 requests per hour per IP
- Burst allowance: 20 requests
- 429 status code with Retry-After header

---

## Conclusion

Memorio's security architecture represents a **defense-in-depth** approach with multiple layers of protection:

1. **Infrastructure**: Enterprise cloud providers (Netlify, Supabase/AWS)
2. **Network**: TLS 1.3 encryption, DDoS protection, security headers
3. **Application**: Rate limiting, input validation, secure sessions
4. **Database**: Row-level security, encryption, automated backups
5. **Access Control**: RBAC, multi-tenancy, audit logging
6. **Monitoring**: Real-time alerts, incident response, audit trails

This comprehensive security posture ensures that:
- ✅ **Family data remains private and secure**
- ✅ **Funeral homes maintain complete data isolation**
- ✅ **Compliance requirements are met**
- ✅ **Security incidents are detected and responded to quickly**
- ✅ **The platform scales securely as it grows**

---

**For Questions or Security Concerns**:  
Email: security@memorio.ai  
Response Time: < 24 hours for security inquiries

**Document Control**:  
Version: 1.0  
Last Review: January 12, 2026  
Next Review: April 12, 2026  
Owner: Memorio Security Team
