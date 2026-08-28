-- =====================================================================
-- MY TOWN DIGITAL & TECH COMMUNITY — Phase 1 Migration
-- Core schema, roles, RLS policies
-- Run this in the Supabase SQL Editor (or via `supabase db push`)
-- =====================================================================

create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";

-- =====================================================================
-- 1. ENUM TYPES
-- =====================================================================

create type user_role as enum (
  'member',
  'mentor',
  'organization',
  'admin',
  'super_admin'
);

create type professional_status as enum (
  'student',
  'freelancer',
  'entrepreneur',
  'employed',
  'job_seeker',
  'developer',
  'designer',
  'teacher',
  'researcher',
  'other'
);

create type experience_level as enum (
  'beginner',
  'intermediate',
  'advanced',
  'expert'
);

create type availability_status as enum (
  'available_freelance',
  'open_to_opportunities',
  'not_available'
);

create type visibility_level as enum (
  'public',
  'members_only',
  'private'
);

create type project_status as enum (
  'completed',
  'in_progress',
  'prototype'
);

create type opportunity_category as enum (
  'job',
  'internship',
  'scholarship',
  'fellowship',
  'training',
  'competition',
  'grant',
  'freelance',
  'volunteer',
  'hackathon'
);

create type opportunity_mode as enum ('remote', 'onsite', 'hybrid');

create type saved_opportunity_status as enum ('interested', 'applied', 'completed');

create type mentorship_status as enum ('pending', 'accepted', 'rejected', 'completed');

create type verification_status as enum ('unverified', 'pending', 'approved', 'rejected', 'more_info_requested');

create type report_status as enum ('pending', 'under_review', 'resolved', 'rejected');

create type report_target_type as enum ('profile', 'project', 'service', 'opportunity', 'other');

-- =====================================================================
-- 2. PLATFORM SETTINGS (singleton row, admin-editable)
-- =====================================================================

create table platform_settings (
  id uuid primary key default uuid_generate_v4(),
  platform_name text not null default 'MY TOWN DIGITAL & TECH COMMUNITY',
  logo_url text,
  favicon_url text,
  description text,
  contact_email text,
  contact_phone text,
  social_links jsonb default '{}'::jsonb,
  primary_color text default '#0F172A',
  accent_color text default '#2563EB',
  community_location text,
  footer_text text,
  updated_at timestamptz not null default now(),
  updated_by uuid
);

insert into platform_settings (platform_name) values ('MY TOWN DIGITAL & TECH COMMUNITY');

-- =====================================================================
-- 3. NEIGHBORHOODS (admin-managed lookup, not hard-coded)
-- =====================================================================

create table neighborhoods (
  id uuid primary key default uuid_generate_v4(),
  name text not null unique,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid
);

-- =====================================================================
-- 4. PROFILES (extends auth.users)
-- =====================================================================

create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  username text not null unique,
  email text not null unique,
  phone_number text,
  gender text,
  date_of_birth date,
  town text,
  neighborhood_id uuid references neighborhoods(id),
  state text,
  country text,

  professional_headline text,
  bio text,
  primary_skill_id uuid,
  experience_level experience_level,
  years_of_experience int,
  education text,
  certifications text,
  languages text,

  portfolio_url text,
  github_url text,
  linkedin_url text,
  facebook_url text,
  twitter_url text,
  youtube_url text,

  professional_status professional_status,
  availability_status availability_status default 'not_available',
  profile_photo_url text,

  role user_role not null default 'member',
  is_verified boolean not null default false,
  verification_status verification_status not null default 'unverified',
  is_suspended boolean not null default false,

  phone_visibility visibility_level not null default 'private',
  email_visibility visibility_level not null default 'private',
  location_visibility visibility_level not null default 'members_only',
  social_links_visibility visibility_level not null default 'public',
  portfolio_visibility visibility_level not null default 'public',
  profile_visibility visibility_level not null default 'public',

  is_demo boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_profiles_username on profiles(username);
create index idx_profiles_role on profiles(role);
create index idx_profiles_neighborhood on profiles(neighborhood_id);
create index idx_profiles_verification on profiles(verification_status);

-- =====================================================================
-- 5. SKILLS
-- =====================================================================

create table skill_categories (
  id uuid primary key default uuid_generate_v4(),
  name text not null unique,
  description text,
  sort_order int default 0,
  created_at timestamptz not null default now()
);

create table skills (
  id uuid primary key default uuid_generate_v4(),
  category_id uuid references skill_categories(id) on delete set null,
  name text not null unique,
  description text,
  created_at timestamptz not null default now()
);

alter table profiles
  add constraint fk_primary_skill foreign key (primary_skill_id) references skills(id) on delete set null;

create table member_skills (
  id uuid primary key default uuid_generate_v4(),
  profile_id uuid not null references profiles(id) on delete cascade,
  skill_id uuid not null references skills(id) on delete cascade,
  is_primary boolean default false,
  created_at timestamptz not null default now(),
  unique (profile_id, skill_id)
);

create index idx_member_skills_profile on member_skills(profile_id);
create index idx_member_skills_skill on member_skills(skill_id);

-- =====================================================================
-- 6. PROJECTS
-- =====================================================================

create table projects (
  id uuid primary key default uuid_generate_v4(),
  owner_id uuid not null references profiles(id) on delete cascade,
  title text not null,
  slug text not null unique,
  description text,
  category_id uuid references skill_categories(id) on delete set null,
  technologies text[],
  image_url text,
  project_url text,
  github_url text,
  completion_date date,
  status project_status not null default 'in_progress',
  is_demo boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_projects_owner on projects(owner_id);
create index idx_projects_status on projects(status);
create index idx_projects_slug on projects(slug);

create table project_members (
  id uuid primary key default uuid_generate_v4(),
  project_id uuid not null references projects(id) on delete cascade,
  profile_id uuid not null references profiles(id) on delete cascade,
  role_on_project text,
  created_at timestamptz not null default now(),
  unique (project_id, profile_id)
);

-- =====================================================================
-- 7. SERVICES MARKETPLACE
-- =====================================================================

create table services (
  id uuid primary key default uuid_generate_v4(),
  profile_id uuid not null references profiles(id) on delete cascade,
  title text not null,
  description text,
  price_rate text,
  category_id uuid references skill_categories(id) on delete set null,
  delivery_period text,
  contact_method text,
  portfolio_url text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_services_profile on services(profile_id);

-- =====================================================================
-- 8. ACHIEVEMENTS
-- =====================================================================

create table achievements (
  id uuid primary key default uuid_generate_v4(),
  profile_id uuid not null references profiles(id) on delete cascade,
  title text not null,
  organization text,
  achieved_on date,
  description text,
  certificate_url text,
  verification_status verification_status not null default 'unverified',
  verified_by uuid references profiles(id),
  created_at timestamptz not null default now()
);

create index idx_achievements_profile on achievements(profile_id);

-- =====================================================================
-- 9. ORGANIZATIONS
-- =====================================================================

create table organizations (
  id uuid primary key default uuid_generate_v4(),
  owner_profile_id uuid references profiles(id) on delete set null,
  name text not null,
  description text,
  logo_url text,
  website_url text,
  is_approved boolean not null default false,
  created_at timestamptz not null default now()
);

-- =====================================================================
-- 10. OPPORTUNITIES
-- =====================================================================

create table opportunities (
  id uuid primary key default uuid_generate_v4(),
  posted_by uuid not null references profiles(id) on delete cascade,
  organization_id uuid references organizations(id) on delete set null,
  title text not null,
  slug text not null unique,
  description text,
  organization_name text,
  location text,
  mode opportunity_mode,
  deadline date,
  requirements text,
  application_link text,
  category opportunity_category not null,
  is_approved boolean not null default false,
  is_demo boolean not null default false,
  created_at timestamptz not null default now()
);

create index idx_opportunities_category on opportunities(category);
create index idx_opportunities_deadline on opportunities(deadline);

create table saved_opportunities (
  id uuid primary key default uuid_generate_v4(),
  profile_id uuid not null references profiles(id) on delete cascade,
  opportunity_id uuid not null references opportunities(id) on delete cascade,
  status saved_opportunity_status not null default 'interested',
  created_at timestamptz not null default now(),
  unique (profile_id, opportunity_id)
);

-- =====================================================================
-- 11. EVENTS
-- =====================================================================

create table events (
  id uuid primary key default uuid_generate_v4(),
  organizer_id uuid not null references profiles(id) on delete cascade,
  name text not null,
  slug text not null unique,
  description text,
  event_date date not null,
  start_time time,
  end_time time,
  location text,
  registration_link text,
  max_attendees int,
  image_url text,
  is_demo boolean not null default false,
  created_at timestamptz not null default now()
);

create table event_registrations (
  id uuid primary key default uuid_generate_v4(),
  event_id uuid not null references events(id) on delete cascade,
  profile_id uuid not null references profiles(id) on delete cascade,
  registered_at timestamptz not null default now(),
  unique (event_id, profile_id)
);

-- =====================================================================
-- 12. MENTORSHIP
-- =====================================================================

create table mentors (
  id uuid primary key default uuid_generate_v4(),
  profile_id uuid not null unique references profiles(id) on delete cascade,
  areas_of_mentorship text[],
  availability text,
  is_approved boolean not null default false,
  created_at timestamptz not null default now()
);

create table mentorship_requests (
  id uuid primary key default uuid_generate_v4(),
  mentor_id uuid not null references mentors(id) on delete cascade,
  requester_id uuid not null references profiles(id) on delete cascade,
  message text,
  status mentorship_status not null default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- =====================================================================
-- 13. NOTIFICATIONS & ANNOUNCEMENTS
-- =====================================================================

create table notifications (
  id uuid primary key default uuid_generate_v4(),
  profile_id uuid not null references profiles(id) on delete cascade,
  type text not null,
  title text not null,
  body text,
  link text,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create index idx_notifications_profile on notifications(profile_id, is_read);

create table announcements (
  id uuid primary key default uuid_generate_v4(),
  posted_by uuid not null references profiles(id) on delete cascade,
  title text not null,
  body text not null,
  is_published boolean not null default true,
  created_at timestamptz not null default now()
);

-- =====================================================================
-- 14. VERIFICATION, CONTACT, REPORTS
-- =====================================================================

create table verification_requests (
  id uuid primary key default uuid_generate_v4(),
  profile_id uuid not null references profiles(id) on delete cascade,
  supporting_info text,
  status verification_status not null default 'pending',
  reviewed_by uuid references profiles(id),
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

create table contact_requests (
  id uuid primary key default uuid_generate_v4(),
  target_profile_id uuid not null references profiles(id) on delete cascade,
  sender_name text not null,
  sender_email text not null,
  message text not null,
  created_at timestamptz not null default now()
);

create table reports (
  id uuid primary key default uuid_generate_v4(),
  reported_by uuid not null references profiles(id) on delete cascade,
  target_type report_target_type not null,
  target_id uuid,
  reason text not null,
  details text,
  status report_status not null default 'pending',
  handled_by uuid references profiles(id),
  created_at timestamptz not null default now()
);

-- =====================================================================
-- 15. AUDIT LOG
-- =====================================================================

create table audit_logs (
  id uuid primary key default uuid_generate_v4(),
  admin_id uuid not null references profiles(id),
  action text not null,
  target_table text,
  target_id uuid,
  metadata jsonb default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- =====================================================================
-- 16. HELPER FUNCTIONS
-- =====================================================================

-- Returns the role of the currently authenticated user
create or replace function auth_role()
returns user_role
language sql
security definer
stable
as $$
  select role from profiles where id = auth.uid();
$$;

create or replace function is_admin()
returns boolean
language sql
security definer
stable
as $$
  select exists (
    select 1 from profiles
    where id = auth.uid()
      and role in ('admin', 'super_admin')
  );
$$;

-- Keeps updated_at fresh
create or replace function set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger trg_profiles_updated before update on profiles
  for each row execute function set_updated_at();
create trigger trg_projects_updated before update on projects
  for each row execute function set_updated_at();
create trigger trg_services_updated before update on services
  for each row execute function set_updated_at();
create trigger trg_mentorship_updated before update on mentorship_requests
  for each row execute function set_updated_at();

-- =====================================================================
-- 17. ROW LEVEL SECURITY
-- =====================================================================

alter table profiles enable row level security;
alter table neighborhoods enable row level security;
alter table skill_categories enable row level security;
alter table skills enable row level security;
alter table member_skills enable row level security;
alter table projects enable row level security;
alter table project_members enable row level security;
alter table services enable row level security;
alter table achievements enable row level security;
alter table organizations enable row level security;
alter table opportunities enable row level security;
alter table saved_opportunities enable row level security;
alter table events enable row level security;
alter table event_registrations enable row level security;
alter table mentors enable row level security;
alter table mentorship_requests enable row level security;
alter table notifications enable row level security;
alter table announcements enable row level security;
alter table verification_requests enable row level security;
alter table contact_requests enable row level security;
alter table reports enable row level security;
alter table audit_logs enable row level security;
alter table platform_settings enable row level security;

-- ---- PROFILES ----
create policy "Public profiles are viewable by everyone"
  on profiles for select
  using (profile_visibility = 'public' or auth.uid() = id or is_admin());

create policy "Users can insert their own profile"
  on profiles for insert
  with check (auth.uid() = id);

create policy "Users can update their own profile (not role/verification)"
  on profiles for update
  using (auth.uid() = id or is_admin())
  with check (
    is_admin()
    or (auth.uid() = id
        and role = (select role from profiles where id = auth.uid())
        and is_verified = (select is_verified from profiles where id = auth.uid())
        and verification_status = (select verification_status from profiles where id = auth.uid()))
  );

create policy "Admins can delete profiles"
  on profiles for delete
  using (is_admin());

-- ---- NEIGHBORHOODS ----
create policy "Neighborhoods are viewable by everyone"
  on neighborhoods for select using (true);
create policy "Admins manage neighborhoods"
  on neighborhoods for all using (is_admin()) with check (is_admin());

-- ---- SKILLS / CATEGORIES ----
create policy "Skill categories viewable by everyone"
  on skill_categories for select using (true);
create policy "Admins manage skill categories"
  on skill_categories for all using (is_admin()) with check (is_admin());

create policy "Skills viewable by everyone"
  on skills for select using (true);
create policy "Admins manage skills"
  on skills for all using (is_admin()) with check (is_admin());

create policy "Member skills viewable by everyone"
  on member_skills for select using (true);
create policy "Users manage their own skills"
  on member_skills for all
  using (auth.uid() = profile_id or is_admin())
  with check (auth.uid() = profile_id or is_admin());

-- ---- PROJECTS ----
create policy "Projects viewable by everyone"
  on projects for select using (true);
create policy "Owners manage their own projects"
  on projects for all
  using (auth.uid() = owner_id or is_admin())
  with check (auth.uid() = owner_id or is_admin());

create policy "Project members viewable by everyone"
  on project_members for select using (true);
create policy "Project owners manage members"
  on project_members for all
  using (auth.uid() = (select owner_id from projects where id = project_id) or is_admin())
  with check (auth.uid() = (select owner_id from projects where id = project_id) or is_admin());

-- ---- SERVICES ----
create policy "Services viewable by everyone"
  on services for select using (is_active or auth.uid() = profile_id or is_admin());
create policy "Owners manage their own services"
  on services for all
  using (auth.uid() = profile_id or is_admin())
  with check (auth.uid() = profile_id or is_admin());

-- ---- ACHIEVEMENTS ----
create policy "Achievements viewable by everyone"
  on achievements for select using (true);
create policy "Owners manage their own achievements"
  on achievements for insert with check (auth.uid() = profile_id);
create policy "Owners update their own achievements"
  on achievements for update
  using (auth.uid() = profile_id or is_admin())
  with check (
    is_admin()
    or (auth.uid() = profile_id
        and verification_status = (select verification_status from achievements a where a.id = id))
  );
create policy "Admins delete achievements"
  on achievements for delete using (is_admin() or auth.uid() = profile_id);

-- ---- ORGANIZATIONS ----
create policy "Organizations viewable by everyone"
  on organizations for select using (true);
create policy "Owners manage their organization"
  on organizations for all
  using (auth.uid() = owner_profile_id or is_admin())
  with check (auth.uid() = owner_profile_id or is_admin());

-- ---- OPPORTUNITIES ----
create policy "Approved opportunities viewable by everyone"
  on opportunities for select
  using (is_approved or auth.uid() = posted_by or is_admin());
create policy "Admins and orgs create opportunities"
  on opportunities for insert
  with check (
    is_admin()
    or exists (select 1 from profiles where id = auth.uid() and role in ('organization', 'admin', 'super_admin'))
  );
create policy "Owners/admins update opportunities"
  on opportunities for update
  using (auth.uid() = posted_by or is_admin())
  with check (is_admin() or auth.uid() = posted_by);
create policy "Owners/admins delete opportunities"
  on opportunities for delete using (auth.uid() = posted_by or is_admin());

create policy "Users manage their saved opportunities"
  on saved_opportunities for all
  using (auth.uid() = profile_id)
  with check (auth.uid() = profile_id);

-- ---- EVENTS ----
create policy "Events viewable by everyone"
  on events for select using (true);
create policy "Admins and organizers manage events"
  on events for insert with check (is_admin() or auth.uid() = organizer_id);
create policy "Organizers/admins update events"
  on events for update using (auth.uid() = organizer_id or is_admin());
create policy "Organizers/admins delete events"
  on events for delete using (auth.uid() = organizer_id or is_admin());

create policy "Users manage their own registrations"
  on event_registrations for all
  using (auth.uid() = profile_id or is_admin())
  with check (auth.uid() = profile_id or is_admin());

-- ---- MENTORSHIP ----
create policy "Approved mentors viewable by everyone"
  on mentors for select using (is_approved or auth.uid() = profile_id or is_admin());
create policy "Users apply to become mentors"
  on mentors for insert with check (auth.uid() = profile_id);
create policy "Mentors/admins update mentor record"
  on mentors for update using (auth.uid() = profile_id or is_admin());

create policy "Requesters and mentors view their requests"
  on mentorship_requests for select
  using (
    auth.uid() = requester_id
    or auth.uid() = (select profile_id from mentors where id = mentor_id)
    or is_admin()
  );
create policy "Members create mentorship requests"
  on mentorship_requests for insert with check (auth.uid() = requester_id);
create policy "Mentors update request status"
  on mentorship_requests for update
  using (auth.uid() = (select profile_id from mentors where id = mentor_id) or is_admin());

-- ---- NOTIFICATIONS ----
create policy "Users see only their own notifications"
  on notifications for select using (auth.uid() = profile_id);
create policy "Users mark their own notifications read"
  on notifications for update using (auth.uid() = profile_id);
create policy "System/admins insert notifications"
  on notifications for insert with check (true);

-- ---- ANNOUNCEMENTS ----
create policy "Published announcements viewable by everyone"
  on announcements for select using (is_published or is_admin());
create policy "Admins manage announcements"
  on announcements for all using (is_admin()) with check (is_admin());

-- ---- VERIFICATION REQUESTS ----
create policy "Users view their own verification requests"
  on verification_requests for select using (auth.uid() = profile_id or is_admin());
create policy "Users create their own verification requests"
  on verification_requests for insert with check (auth.uid() = profile_id);
create policy "Only admins update verification requests"
  on verification_requests for update using (is_admin());

-- ---- CONTACT REQUESTS ----
create policy "Recipients and admins view contact requests"
  on contact_requests for select using (auth.uid() = target_profile_id or is_admin());
create policy "Anyone can submit a contact request"
  on contact_requests for insert with check (true);

-- ---- REPORTS ----
create policy "Reporters and admins view reports"
  on reports for select using (auth.uid() = reported_by or is_admin());
create policy "Authenticated users create reports"
  on reports for insert with check (auth.uid() = reported_by);
create policy "Only admins update reports"
  on reports for update using (is_admin());

-- ---- AUDIT LOGS ----
create policy "Only admins read audit logs"
  on audit_logs for select using (is_admin());
create policy "Only admins write audit logs"
  on audit_logs for insert with check (is_admin());

-- ---- PLATFORM SETTINGS ----
create policy "Settings are publicly readable"
  on platform_settings for select using (true);
create policy "Only admins update settings"
  on platform_settings for update using (is_admin());

-- =====================================================================
-- End of Phase 1 migration
-- =====================================================================
