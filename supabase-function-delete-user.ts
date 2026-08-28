// Supabase Edge Function: delete-user
// Deploy with: supabase functions deploy delete-user
// Deletes an auth.users row (which cascades to `profiles` and
// everything that references it). This MUST run server-side because
// it needs the service_role key — that key must never reach the
// frontend, which is exactly why this exists as an Edge Function
// instead of a direct client-side call.
//
// Security: verifies the CALLER (via their own JWT) is an admin or
// super_admin before deleting anything. A non-admin JWT, or none at
// all, is rejected.

import { serve } from 'https://deno.land/std@0.192.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

serve(async (req) => {
  try {
    if (req.method !== 'POST') {
      return new Response(JSON.stringify({ error: 'Method not allowed' }), { status: 405 });
    }

    const authHeader = req.headers.get('Authorization') || '';
    const callerJwt = authHeader.replace('Bearer ', '');
    if (!callerJwt) {
      return new Response(JSON.stringify({ error: 'Missing authorization' }), { status: 401 });
    }

    const { targetUserId } = await req.json();
    if (!targetUserId) {
      return new Response(JSON.stringify({ error: 'targetUserId is required' }), { status: 400 });
    }

    // Client scoped to the caller's own JWT — used only to verify who's calling.
    const callerClient = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
      global: { headers: { Authorization: `Bearer ${callerJwt}` } },
    });

    const { data: { user: caller }, error: callerError } = await callerClient.auth.getUser(callerJwt);
    if (callerError || !caller) {
      return new Response(JSON.stringify({ error: 'Invalid session' }), { status: 401 });
    }

    const { data: callerProfile, error: profileError } = await callerClient
      .from('profiles')
      .select('role')
      .eq('id', caller.id)
      .single();

    if (profileError || !callerProfile || !['admin', 'super_admin'].includes(callerProfile.role)) {
      return new Response(JSON.stringify({ error: 'Forbidden — admin role required' }), { status: 403 });
    }

    if (targetUserId === caller.id) {
      return new Response(JSON.stringify({ error: 'Admins cannot delete their own account this way' }), { status: 400 });
    }

    // Now perform the privileged delete with the service role client.
    const adminClient = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);
    const { error: deleteError } = await adminClient.auth.admin.deleteUser(targetUserId);

    if (deleteError) {
      return new Response(JSON.stringify({ error: deleteError.message }), { status: 500 });
    }

    // Audit log entry for the deletion itself.
    await adminClient.from('audit_logs').insert({
      admin_id: caller.id,
      action: 'member_deleted',
      target_table: 'profiles',
      target_id: targetUserId,
      metadata: {},
    });

    return new Response(JSON.stringify({ success: true }), { status: 200 });
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), { status: 500 });
  }
});
