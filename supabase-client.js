// =====================================================================
// Supabase client initialization
// SUPABASE_URL and SUPABASE_ANON_KEY are injected at build/deploy time
// (see .env.example). NEVER put the service_role key here — anon key
// only, RLS does the rest.
// =====================================================================

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = window.__ENV__?.SUPABASE_URL || '';
const SUPABASE_ANON_KEY = window.__ENV__?.SUPABASE_ANON_KEY || '';

if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
  console.error(
    'Missing Supabase configuration. Set SUPABASE_URL and SUPABASE_ANON_KEY ' +
    '(see .env.example) and inject them into window.__ENV__ before this script loads.'
  );
}

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true,
  },
});
