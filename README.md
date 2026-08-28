# MY TOWN DIGITAL &amp; TECH COMMUNITY

A full-stack platform for discovering, showcasing and connecting young
digital & tech talent in a local community — profiles, skills,
projects, services, opportunities, events, mentorship, and an admin
system to run it all.

**Stack:** HTML5 / CSS3 / vanilla JS frontend, Supabase (PostgreSQL +
Auth + Storage) backend. Deployable to Netlify or Vercel.

---

## ✅ Phase 1 — what's built so far

- Project structure and build tooling
- Complete PostgreSQL schema (23 tables) with enums, indexes, and
  triggers — `database/migrations/001_initial_schema.sql`
- Auto-provisioning of a `profiles` row on signup —
  `database/migrations/002_auth_trigger.sql`
- Secure first-super-admin setup procedure (no public "make me admin"
  button anywhere) — `database/migrations/003_super_admin_setup.sql`
- Demo/seed data for skills, categories and neighborhoods, all
  removable in one query — `database/migrations/004_seed_data.sql`
- Row Level Security policies on every table (see schema file, Section
  17) enforcing:
  - Users can only edit their own profile, and can't change their own
    `role` or verification status
  - Only admins can verify, suspend, or change roles
  - Only admins (or approved organizations) can post opportunities
  - Everything else follows least-privilege by default
- Supabase client + auth module (register, login, logout, password
  reset, session/role guard) — `assets/js/supabase-client.js`,
  `assets/js/auth.js`
- Working homepage pulling **live** stats and featured content from
  the database (no fake numbers) — `index.html`, `assets/js/home.js`
- Working registration and login pages wired to real Supabase Auth
- Member dashboard and Admin dashboard skeletons, both gated by
  `requireRole()` and pulling real counts

## ✅ Phase 2 — what's built

- Public member profile page respecting per-field privacy settings
  (phone/email/location/socials/portfolio each independently
  public/members-only/private) — `pages/public/member-profile.html`
- Member profile edit form wired to real `profiles` updates — never
  sends `role`/`is_verified`/`verification_status`, and RLS blocks
  those columns server-side even if it tried —
  `pages/member/profile.html`
- Public skills directory grouped by category, each skill linking into
  filtered search — `pages/public/skills.html`
- Member's own skill management (add/remove real rows in
  `member_skills`) — `pages/member/skills.html`
- Full member search/discovery page: text search, skill filter,
  category filter, experience level, availability, professional
  status, sorting, and real pagination (12/page) —
  `pages/public/members.html`

## ✅ Phase 3 — what's built

- Member project management: create/edit/delete with auto-generated
  unique slugs, technologies list, status, links —
  `pages/member/projects.html`
- Public project showcase (filter by status, sort) and project detail
  page (privacy-safe: only ever shows what's actually in the DB, no
  fake team members or stats) — `pages/public/projects.html`,
  `pages/public/project-detail.html`
- Member services management (create/edit/delete, active/inactive
  toggle) — `pages/member/services.html`
- Public searchable services marketplace —
  `pages/public/services.html`
- Member achievements (add/delete), each showing real verification
  status pulled from `verification_status` — `pages/member/achievements.html`
- Verification request flow: members submit a request from Settings,
  it lands in `verification_requests` as `pending`; only admins can
  change its status (RLS-enforced) — `pages/member/settings.html`
- Password reset request wired into Settings

## ✅ Phase 4 — what's built

- Public opportunities listing with text search, category filter, mode
  filter, sort by deadline/newest — `pages/public/opportunities.html`
- Opportunity detail page with live save/apply status tracking
  (Interested / Applied / Completed, or remove) against
  `saved_opportunities` — `pages/public/opportunity-detail.html`
- Member "My Opportunities" view of everything they've saved —
  `pages/member/opportunities.html`
- Opportunity posting form gated to `organization`/`admin`/`super_admin`
  roles both in the UI and via RLS; admin posts go live immediately,
  organization posts default to pending approval —
  `pages/member/post-opportunity.html`, `pages/member/my-opportunities-posted.html`
- Public events listing (upcoming/past) and event detail page with a
  real registration flow, capacity tracking against `max_attendees`,
  and cancel-registration support — `pages/public/events.html`,
  `pages/public/event-detail.html`
- Member "My Events": registrations + ability to organize new events
  (any authenticated member can organize, per RLS) —
  `pages/member/events.html`
- Mentorship: public mentor directory with a request-mentorship
  action, a member-side "become a mentor" application, and a
  mentor's accept/reject queue for incoming requests —
  `pages/public/mentorship.html`, `pages/member/mentorship.html`

## ✅ Phase 5 — what's built

- Member notifications inbox: list, click-to-mark-read, mark-all-read,
  and an unread-count badge in the sidebar —
  `pages/member/notifications.html`, `assets/js/notifications-badge.js`
- Contact/hire form: visitors reach out to a member without ever
  seeing their real email/phone; the member sees it in their
  dashboard — `pages/public/contact-member.html`,
  `pages/member/inquiries.html`
- Report system: logged-in users can report a profile, project,
  service, or opportunity with a reason and details, landing as
  `pending` in `reports` (admin review UI comes in Phase 6) —
  `pages/public/report.html`, with a Report link wired into member
  profiles
- Public community news feed and a live "latest announcement" banner
  surfaced on the member dashboard —
  `pages/public/announcements.html`

## ✅ Phase 6 — what's built

- Admin member management: search, filter by role/verified/suspended,
  inline role changes, verify, suspend/unsuspend, and real account
  deletion via a Supabase Edge Function — `pages/admin/members.html`,
  `supabase/functions/delete-user/index.ts`
- Verification request review queue: approve / reject / request more
  info, flips the member's real `is_verified` flag —
  `pages/admin/verification.html`
- Skills & categories management (add/remove) —
  `pages/admin/skills.html`
- Neighborhood management (add/activate/deactivate/delete) —
  `pages/admin/neighborhoods.html`
- Opportunity approval queue (approve/unpublish/delete) —
  `pages/admin/opportunities.html`
- Event management with a real attendee list per event —
  `pages/admin/events.html`
- Mentor application approval/revocation —
  `pages/admin/mentors.html`
- Announcement composer (publish/unpublish/delete) —
  `pages/admin/announcements.html`
- Report review queue with status workflow —
  `pages/admin/reports.html`
- Read-only audit log viewer, populated automatically by every action
  above — `pages/admin/audit-log.html`, `assets/js/audit-log.js`
- Platform settings (name, logo, favicon, contact info, colors,
  footer) — `pages/admin/settings.html`, applied live on the homepage

### Important: deploy the `delete-user` Edge Function

Deleting a member's *account* (not just their profile row) requires
the `service_role` key, which must never touch the browser. That's
why it's implemented as a Supabase Edge Function instead of a direct
table delete:

```bash
supabase functions deploy delete-user
```

Until this is deployed, the "Delete" button on `pages/admin/members.html`
will fail with a clear error rather than silently leaving an orphaned
login — suspend still works immediately with no extra setup and is
sufficient for most moderation needs.

## 🚧 Not built yet (Phase 7)

- Full security review pass and RLS penetration testing
- Performance optimization (pagination tuning, image optimization, query auditing)
- Complete accessibility and mobile QA pass
- SEO polish (structured data, sitemap, robots.txt)
- End-to-end test pass through every flow in the original spec
- Phase 6: full admin member/content management tables, audit log viewer, settings page
- Phase 7: security review, performance pass, SEO polish, full test pass

Each phase builds directly on this Phase 1 foundation — nothing here
needs to be redone.

---

## Setup

### 1. Create a Supabase project
Go to [supabase.com](https://supabase.com), create a new project, and
note your **Project URL** and **anon/public key** (Project Settings →
API). Never use the `service_role` key in any frontend file.

### 2. Run the database migrations
In the Supabase SQL Editor, run these files **in order**:
1. `database/migrations/001_initial_schema.sql`
2. `database/migrations/002_auth_trigger.sql`
3. `database/migrations/004_seed_data.sql` (optional, demo lookup data)

Do **not** run `003_super_admin_setup.sql` yet — see step 5.

### 3. Configure environment variables
Copy `.env.example` to `.env` and fill in your project's URL and anon
key. Locally:

```bash
npm install
SUPABASE_URL=https://YOUR-REF.supabase.co SUPABASE_ANON_KEY=your-anon-key npm run dev
```

On Netlify/Vercel, set `SUPABASE_URL` and `SUPABASE_ANON_KEY` as
environment variables in the dashboard — the build command
(`npm run build`) generates `assets/js/env-config.js` automatically at
deploy time. This file is git-ignored and never committed.

### 4. Enable email auth
In Supabase Dashboard → Authentication → Providers, confirm
Email is enabled. Under Authentication → URL Configuration, set your
site URL (e.g. your Netlify domain) so confirmation/reset emails link
back correctly.

### 5. Create your first Super Administrator
1. Register a real account through `/pages/public/register.html`.
2. In Supabase SQL Editor, find its id:
   ```sql
   select id, email from auth.users where email = 'you@example.com';
   ```
3. Open `database/migrations/003_super_admin_setup.sql`, paste that id
   in, and run it. This is the only sanctioned way to create an admin
   — there is no in-app mechanism for it, by design (Section 37).

### 6. Deploy the delete-user Edge Function

```bash
supabase login
supabase link --project-ref YOUR-PROJECT-REF
supabase functions deploy delete-user
```

The function reads `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` from
Supabase's own Edge Function environment (set automatically) — you do
not need to configure these yourself, and this key never appears in
any frontend file.

### 7. Deploy
- **Netlify:** connect the repo, build command `npm run build`,
  publish directory `.`. `netlify.toml` already defines pretty URLs
  for `/members/:username`, `/projects/:slug`, `/opportunities/:slug`,
  `/events/:slug`.
- **Vercel:** import the repo, set the same environment variables,
  build command `npm run build`, output directory `.`.

---

## Local development

```bash
npm install
npm run dev
```

This regenerates `assets/js/env-config.js` from your local environment
variables and serves the project at `http://localhost:3000`.

---

## Project structure

```
/database/migrations   SQL migrations, run in numeric order
/assets/css            Stylesheets (main, forms, dashboard)
/assets/js             supabase-client.js, auth.js, page scripts
/pages/public           Homepage-adjacent public pages (login, register, ...)
/pages/member           Member dashboard & tools
/pages/admin            Admin dashboard & management tools
/scripts               Build-time helpers (env injection)
index.html             Homepage
```

## Security notes

- RLS is enabled on every table; the frontend is never the only line
  of defense.
- The anon key is safe to expose (it's designed to be) — RLS is what
  actually restricts access. The `service_role` key must never appear
  in any file under `/assets`, `/pages`, or anywhere shipped to the
  browser.
- Role changes, verification, and suspensions are only possible via
  admin-gated policies (`is_admin()` in SQL) — a member editing their
  own profile cannot smuggle in a role or verification change even by
  calling the API directly.
