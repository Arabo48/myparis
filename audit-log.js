// Every destructive or sensitive admin action should call this so it
// shows up in the Audit Log (Section 30). RLS restricts inserts here
// to admins/super_admins already, so this simply wraps that call.

import { supabase } from './supabase-client.js';

export async function logAdminAction({ adminId, action, targetTable, targetId, metadata = {} }) {
  await supabase.from('audit_logs').insert({
    admin_id: adminId,
    action,
    target_table: targetTable,
    target_id: targetId,
    metadata,
  });
}
