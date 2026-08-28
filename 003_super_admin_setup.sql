-- =====================================================================
-- INITIAL SUPER ADMIN SETUP
-- There is deliberately NO public "make me admin" button or endpoint
-- anywhere in the app (see RLS: only is_admin() can change `role`).
--
-- To promote the first Super Administrator:
--   1. Register a normal account through the app's signup form.
--   2. Get its user id: select id, email from auth.users where email = 'you@example.com';
--   3. Run the statement below directly in the Supabase SQL Editor
--      (this runs with service-role privileges and bypasses RLS —
--      that is the ONLY sanctioned way to create the first admin).
-- =====================================================================

update profiles
set role = 'super_admin',
    is_verified = true,
    verification_status = 'approved'
where id = 'PASTE-USER-UUID-HERE';

-- After the first super admin exists, all further role changes should
-- go through the Admin Dashboard (Section 19), which is itself gated
-- by the is_admin() check in RLS — never by editing the DB by hand again.
