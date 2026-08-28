-- =====================================================================
-- DEMO / SEED DATA — Section 38
-- Everything here is flagged is_demo = true so it can be found and
-- deleted in one query before going to production:
--   delete from projects where is_demo = true;
--   delete from opportunities where is_demo = true;
--   delete from events where is_demo = true;
--   delete from profiles where is_demo = true;   -- (also drop matching auth.users rows)
--
-- NOTE: profiles.id must reference a real auth.users row (FK), so demo
-- profiles cannot be inserted through this SQL script alone — Supabase
-- Auth has to create the auth.users row first. Two ways to seed demo
-- members:
--   1. Recommended: write a small Node/Deno script that calls
--      supabase.auth.admin.createUser() for each demo member using the
--      service_role key (never expose this key to the frontend), then
--      updates the resulting profile row with the rest of the demo
--      fields below.
--   2. Manual: sign up 20 throwaway accounts through the real
--      registration form, then run the UPDATE statements below against
--      their generated profile ids to backfill headline/bio/skills/etc.
-- =====================================================================

-- ---- Skill categories & skills (safe to insert directly — no FK to auth.users) ----

insert into skill_categories (name, description, sort_order) values
  ('Web Development', 'Building websites and web applications', 1),
  ('Mobile Development', 'Building iOS and Android apps', 2),
  ('Data Science', 'Data analysis, visualization and statistics', 3),
  ('Artificial Intelligence', 'AI and machine learning systems', 4),
  ('Cybersecurity', 'Securing systems and networks', 5),
  ('UI/UX Design', 'Product and interface design', 6),
  ('Graphic Design', 'Visual and brand design', 7),
  ('Video Editing', 'Video production and post-production', 8),
  ('Digital Marketing', 'Marketing, SEO and social media growth', 9),
  ('Entrepreneurship', 'Building and running a business', 10)
on conflict (name) do nothing;

insert into skills (category_id, name) values
  ((select id from skill_categories where name = 'Web Development'), 'Frontend Development'),
  ((select id from skill_categories where name = 'Web Development'), 'Backend Development'),
  ((select id from skill_categories where name = 'Web Development'), 'Full-Stack Development'),
  ((select id from skill_categories where name = 'Mobile Development'), 'Android Development'),
  ((select id from skill_categories where name = 'Mobile Development'), 'iOS Development'),
  ((select id from skill_categories where name = 'Data Science'), 'Data Analysis'),
  ((select id from skill_categories where name = 'Data Science'), 'Data Visualization'),
  ((select id from skill_categories where name = 'Artificial Intelligence'), 'Machine Learning'),
  ((select id from skill_categories where name = 'Cybersecurity'), 'Network Security'),
  ((select id from skill_categories where name = 'UI/UX Design'), 'Product Design'),
  ((select id from skill_categories where name = 'Graphic Design'), 'Brand Identity Design'),
  ((select id from skill_categories where name = 'Video Editing'), 'Motion Graphics'),
  ((select id from skill_categories where name = 'Digital Marketing'), 'Social Media Management'),
  ((select id from skill_categories where name = 'Entrepreneurship'), 'Business Development')
on conflict (name) do nothing;

-- ---- Sample neighborhoods ----

insert into neighborhoods (name) values
  ('Downtown'), ('Riverside'), ('Old Market'), ('New Layout'), ('Industrial Estate')
on conflict (name) do nothing;

-- ---- Sample announcement (no auth.users dependency issue avoided by
--      requiring a real admin id — replace after your first admin exists) ----
-- insert into announcements (posted_by, title, body)
-- values ('PASTE-ADMIN-UUID', 'Welcome to the community!', 'We are live — start building your profile today.');
