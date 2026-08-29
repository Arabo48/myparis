// Shared helpers used across member-facing create/edit forms.

export function slugify(text) {
  return text
    .toString()
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9\s-]/g, '')
    .replace(/\s+/g, '-')
    .replace(/-+/g, '-')
    .slice(0, 80);
}

/**
 * Generates a slug and, if it collides with an existing row, appends
 * a short random suffix until it's unique. `checkFn` should be an
 * async function(candidateSlug) => boolean (true if taken).
 */
export async function uniqueSlug(baseText, checkFn) {
  let base = slugify(baseText) || 'item';
  let candidate = base;
  let attempts = 0;
  while (await checkFn(candidate)) {
    attempts += 1;
    candidate = `${base}-${Math.random().toString(36).slice(2, 6)}`;
    if (attempts > 5) break; // extremely unlikely, but avoid infinite loop
  }
  return candidate;
}

export function escapeHtml(str) {
  const div = document.createElement('div');
  div.textContent = str ?? '';
  return div.innerHTML;
}

/**
 * Fetches the live platform name/logo from platform_settings and applies
 * it to the sidebar brand element (id="sidebarBrand") if present on the
 * page. Call this on every member/admin page so a rename in Platform
 * Settings shows up everywhere immediately, not just the homepage.
 */
export async function applySidebarBrand(supabase) {
  const el = document.getElementById('sidebarBrand');
  if (!el) return;

  const { data } = await supabase
    .from('platform_settings')
    .select('platform_name')
    .limit(1)
    .maybeSingle();

  if (data?.platform_name) {
    el.textContent = data.platform_name;
    document.title = document.title.replace(/MY TOWN DIGITAL & TECH COMMUNITY|ADMIN/i, data.platform_name);
  }
}
 * `pathPrefix` scopes the file under a folder (e.g. the uploader's user id)
 * so per-user storage RLS policies can enforce ownership.
 * Returns { url } on success or { error } on failure — never throws.
 */
export async function uploadFile(supabase, bucket, file, pathPrefix) {
  if (!file) return { error: 'No file selected.' };
  if (file.size > 5 * 1024 * 1024) return { error: 'File is too large (max 5MB).' };

  const ext = file.name.split('.').pop().toLowerCase();
  const safeExt = /^[a-z0-9]+$/.test(ext) ? ext : 'jpg';
  const path = `${pathPrefix}/${Date.now()}.${safeExt}`;

  const { error: uploadError } = await supabase.storage.from(bucket).upload(path, file, {
    cacheControl: '3600',
    upsert: false,
  });

  if (uploadError) return { error: uploadError.message };

  const { data } = supabase.storage.from(bucket).getPublicUrl(path);
  return { url: data.publicUrl };
}

// A scalloped blue seal with a white checkmark — same visual language as
// the familiar "verified" badges on major social platforms, drawn as our
// own original path (not a copy of any trademarked icon).
export const VERIFIED_BADGE_SVG = `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" style="vertical-align:-2px;display:inline-block;" role="img" aria-label="Verified">
  <path d="M12 0l2.6 2.18 3.35-.77 1.28 3.2 3.2 1.28-.77 3.35L24 12l-2.34 2.76.77 3.35-3.2 1.28-1.28 3.2-3.35-.77L12 24l-2.76-2.34-3.35.77-1.28-3.2-3.2-1.28.77-3.35L0 12l2.34-2.76-.77-3.35 3.2-1.28 1.28-3.2 3.35.77L12 0z" fill="#1877F2"/>
  <path d="M9.75 16.2l-3.5-3.5 1.4-1.4 2.1 2.1 5.6-5.6 1.4 1.4-7 7z" fill="#fff"/>
</svg>`;
