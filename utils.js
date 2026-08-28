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
