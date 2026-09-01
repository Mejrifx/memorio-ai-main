#!/usr/bin/env python3
"""
Memorio push-time security brief.

Runs in three places with the same rules:
  1. git pre-commit hook   (.githooks/pre-commit)      -> blocks the commit
  2. GitHub Action         (.github/workflows/security.yml) -> blocks the merge
  3. Netlify build         (netlify.toml build.command)  -> blocks the deploy

Exit 1 on any FAIL. WARN lines never block but are printed for the brief.
No third-party dependencies: must run on a bare python3.
"""
import base64, json, os, re, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCAN_EXT = {'.html', '.js', '.ts', '.tsx', '.md', '.sql', '.toml', '.json', '.txt', '.yml', '.yaml', '.sh', '.css', '.mjs', '.py'}
SKIP_DIRS = {'.git', 'node_modules', '.netlify', 'fonts', 'images', 'backups'}

# ---- secret patterns (FAIL) ------------------------------------------------
SECRET_PATTERNS = [
    (r'sbp_[A-Za-z0-9]{20,}', 'Supabase personal access token'),
    (r'sk-ant-[A-Za-z0-9_-]{10,}', 'Anthropic API key'),
    (r'\bsk-[A-Za-z0-9]{32,}', 'OpenAI-style secret key'),
    (r'\bre_[A-Za-z0-9]{16,}', 'Resend API key'),
    (r'ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}', 'GitHub token'),
    (r'AKIA[0-9A-Z]{16}', 'AWS access key'),
    (r'xox[baprs]-[A-Za-z0-9-]{10,}', 'Slack token'),
    (r'-----BEGIN [A-Z ]*PRIVATE KEY', 'private key'),
    (r'sb_secret_[A-Za-z0-9_-]{10,}', 'Supabase secret API key'),
    (r'(?i)(service_role_key|SUPABASE_SERVICE_ROLE_KEY)\s*[:=]\s*[\'"]?eyJ', 'service-role key assignment'),
    (r'(?i)(api[_-]?key|secret|token|password)\s*[:=]\s*[\'"][A-Za-z0-9+/_\-]{24,}[\'"]', 'hardcoded credential-looking string'),
]
# ---- forbidden files (FAIL) -----------------------------------------------
FORBIDDEN_FILES = [
    r'(^|/)credentials\.md$', r'(^|/)\.env(\..*)?$', r'\.pem$', r'\.key$', r'\.p12$',
    r'(^|/)supabase/diagnostics/', r'(^|/)supabase/\.temp/', r'\.sql\.bak$', r'(^|/)backups?/.*\.json$',
]
# ---- sensitive logging (FAIL) ---------------------------------------------
LOG_PATTERNS = [
    # Only fires when a credential FIELD/VARIABLE is passed to the logger, not when the word
    # appears inside a quoted message. String literals are stripped before matching.
    (r'console\.(log|info|debug|warn)\(([^)]*)\)', 'console logging of credential/token field'),
]
LOG_FIELD_RE = re.compile(r'(\.|\b)(temp_password|tempPassword|access_token|refresh_token|service_role_key|password)\b')
STRING_LIT_RE = re.compile(r"'(?:\\'|[^'])*'|\"(?:\\\"|[^\"])*\"|`(?:\\`|[^`])*`")
# ---- WARN-only checks -----------------------------------------------------
WARN_PATTERNS = [
    (r'[—–]', 'em/en dash in file (house style: none)'),
    (r'[\U0001F300-\U0001FAFF☀-➿]', 'emoji in file (house style: none in UI)'),
    (r'(?i)\b(TODO|FIXME|HACK)\b.*(auth|secur|rls|password|token)', 'security-related TODO left in code'),
    (r'(?i)test with sample data|localhost:\d+', 'debug/local artifact in shipped code'),
    (r'[A-Za-z0-9._%+-]+@(gmail|yahoo|hotmail|outlook|icloud)\.com', 'personal email address (PII?) in file'),
]
ALLOWED_JWT_ROLES = {'anon'}   # the publishable anon key is expected in the frontend


def jwt_role(token):
    try:
        p = token.split('.')[1]; p += '=' * (-len(p) % 4)
        return json.loads(base64.urlsafe_b64decode(p)).get('role')
    except Exception:
        return None


def iter_files(paths=None):
    if paths:
        for p in paths:
            if os.path.isfile(p): yield p
        return
    for dp, dns, fns in os.walk(ROOT):
        dns[:] = [d for d in dns if d not in SKIP_DIRS]
        for fn in fns:
            if os.path.splitext(fn)[1].lower() in SCAN_EXT:
                yield os.path.join(dp, fn)


def main(argv):
    only = argv[1:] if len(argv) > 1 else None
    fails, warns = [], []
    for path in iter_files(only):
        rel = os.path.relpath(path, ROOT).replace(os.sep, '/')
        if rel.startswith('scripts/security-check.py'):
            continue
        for pat in FORBIDDEN_FILES:
            if re.search(pat, rel):
                fails.append(f'{rel}: forbidden file type/location'); break
        try:
            text = open(path, encoding='utf-8', errors='ignore').read()
        except Exception:
            continue
        for pat, label in SECRET_PATTERNS:
            for m in re.finditer(pat, text):
                if '[REMOVED]' in m.group(0) or '[REDACTED' in m.group(0): continue
                line = text.count('\n', 0, m.start()) + 1
                fails.append(f'{rel}:{line}: {label} ({m.group(0)[:12]}...)')
        for m in re.finditer(r'eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{10,}', text):
            role = jwt_role(m.group(0))
            if role and role not in ALLOWED_JWT_ROLES:
                line = text.count('\n', 0, m.start()) + 1
                fails.append(f'{rel}:{line}: JWT with role={role} (only anon may ship)')
        for pat, label in LOG_PATTERNS:
            for m in re.finditer(pat, text):
                args = STRING_LIT_RE.sub('""', m.group(2))
                if LOG_FIELD_RE.search(args):
                    line = text.count('\n', 0, m.start()) + 1
                    fails.append(f'{rel}:{line}: {label}')
        if rel.endswith(('.html', '.js', '.ts')):
            for pat, label in WARN_PATTERNS:
                n = len(re.findall(pat, text))
                if n:
                    warns.append(f'{rel}: {label} x{n}')

    print('=== Memorio security brief ===')
    for w in warns: print('WARN ', w)
    for f in fails: print('FAIL ', f)
    print(f'--- {len(fails)} blocking, {len(warns)} warnings ---')
    if fails:
        print('Blocked. Remove the flagged secret/file (and rotate the credential if it was ever committed), then retry.')
        return 1
    print('Clean. Safe to push.')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
