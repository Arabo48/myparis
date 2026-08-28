// Shared across member pages: adds an unread-count badge next to the
// "Notifications" sidebar link, if present on the page.

import { supabase } from './supabase-client.js';

export async function renderUnreadBadge(profileId) {
  const link = Array.from(document.querySelectorAll('.dashboard-sidebar nav a'))
    .find(a => a.textContent.trim() === 'Notifications');
  if (!link) return;

  const { count } = await supabase
    .from('notifications')
    .select('id', { count: 'exact', head: true })
    .eq('profile_id', profileId)
    .eq('is_read', false);

  if (count && count > 0) {
    const badge = document.createElement('span');
    badge.textContent = count > 9 ? '9+' : String(count);
    badge.style.cssText = 'background:var(--color-primary);color:#fff;font-size:0.7rem;padding:2px 7px;border-radius:999px;margin-left:8px;';
    link.appendChild(badge);
  }
}
