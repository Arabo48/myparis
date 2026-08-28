// Loads homepage stats and featured content from Supabase.
// Every count/list here is a real query, not placeholder data
// (Section 45: no fake UI).

import { supabase } from './supabase-client.js';
import { VERIFIED_BADGE_SVG } from './utils.js';

async function loadStats() {
  const [{ count: members }, { count: skills }, { count: projects }, { count: opportunities }] =
    await Promise.all([
      supabase.from('profiles').select('id', { count: 'exact', head: true }),
      supabase.from('skills').select('id', { count: 'exact', head: true }),
      supabase.from('projects').select('id', { count: 'exact', head: true }),
      supabase.from('opportunities').select('id', { count: 'exact', head: true }).eq('is_approved', true),
    ]);

  setText('statMembers', members ?? 0);
  setText('statSkills', skills ?? 0);
  setText('statProjects', projects ?? 0);
  setText('statOpportunities', opportunities ?? 0);
}

async function loadFeaturedMembers() {
  const { data, error } = await supabase
    .from('profiles')
    .select('username, full_name, professional_headline, profile_photo_url, is_verified')
    .eq('profile_visibility', 'public')
    .eq('is_verified', true)
    .order('created_at', { ascending: false })
    .limit(6);

  const grid = document.getElementById('featuredMembersGrid');
  if (error || !data || data.length === 0) {
    grid.innerHTML = '<p class="placeholder-text">No featured members yet — be the first to join and get verified!</p>';
    return;
  }

  grid.innerHTML = data.map(m => `
    <a class="member-card" href="public-member-profile.html?u=${encodeURIComponent(m.username)}">
      <img src="${m.profile_photo_url || '/images/default-avatar.png'}" alt="" class="avatar" />
      <h3>${escapeHtml(m.full_name)} ${m.is_verified ? VERIFIED_BADGE_SVG : ''}</h3>
      <p>${escapeHtml(m.professional_headline || '')}</p>
    </a>
  `).join('');
}

async function loadRecentProjects() {
  const { data, error } = await supabase
    .from('projects')
    .select('title, slug, description, image_url, status')
    .order('created_at', { ascending: false })
    .limit(6);

  const grid = document.getElementById('recentProjectsGrid');
  if (error || !data || data.length === 0) {
    grid.innerHTML = '<p class="placeholder-text">No projects have been published yet.</p>';
    return;
  }

  grid.innerHTML = data.map(p => `
    <a class="project-card" href="public-project-detail.html?s=${encodeURIComponent(p.slug)}">
      <img src="${p.image_url || '/images/default-project.png'}" alt="" />
      <h3>${escapeHtml(p.title)}</h3>
      <span class="status-badge status-${p.status}">${p.status.replace('_', ' ')}</span>
    </a>
  `).join('');
}

async function loadUpcomingEvents() {
  const today = new Date().toISOString().slice(0, 10);
  const { data, error } = await supabase
    .from('events')
    .select('name, slug, event_date, location')
    .gte('event_date', today)
    .order('event_date', { ascending: true })
    .limit(4);

  const grid = document.getElementById('upcomingEventsGrid');
  if (error || !data || data.length === 0) {
    grid.innerHTML = '<p class="placeholder-text">No upcoming events scheduled yet.</p>';
    return;
  }

  grid.innerHTML = data.map(e => `
    <a class="event-card" href="public-event-detail.html?s=${encodeURIComponent(e.slug)}">
      <h3>${escapeHtml(e.name)}</h3>
      <p>${e.event_date} — ${escapeHtml(e.location || 'TBA')}</p>
    </a>
  `).join('');
}

async function loadPlatformName() {
  const { data } = await supabase.from('platform_settings').select('platform_name, logo_url, favicon_url, footer_text').limit(1).maybeSingle();
  if (data?.platform_name) {
    document.title = data.platform_name;
    const brand = document.getElementById('brand-name');
    if (brand) brand.textContent = data.platform_name;
  }
  if (data?.logo_url) {
    const logo = document.getElementById('brand-logo');
    if (logo) { logo.src = data.logo_url; logo.style.display = 'inline-block'; }
  }
  if (data?.favicon_url) {
    let link = document.querySelector("link[rel~='icon']");
    if (!link) { link = document.createElement('link'); link.rel = 'icon'; document.head.appendChild(link); }
    link.href = data.favicon_url;
  }
  if (data?.footer_text) {
    const footer = document.getElementById('siteFooter');
    if (footer) footer.querySelector('p').textContent = data.footer_text;
  }
}

async function loadGallery() {
  const { data, error } = await supabase
    .from('gallery_images')
    .select('image_url, caption')
    .order('sort_order', { ascending: true })
    .order('created_at', { ascending: false })
    .limit(12);

  if (error || !data || data.length === 0) return;

  const section = document.getElementById('photoGallery');
  const grid = document.getElementById('photoGalleryGrid');
  grid.innerHTML = data.map(g => `
    <div>
      <img src="${g.image_url}" alt="${escapeHtml(g.caption || '')}" loading="lazy" />
      ${g.caption ? `<p class="gallery-caption">${escapeHtml(g.caption)}</p>` : ''}
    </div>
  `).join('');
  section.hidden = false;
}

function setText(id, value) {
  const el = document.getElementById(id);
  if (el) el.textContent = value;
}

function escapeHtml(str) {
  const div = document.createElement('div');
  div.textContent = str;
  return div.innerHTML;
}

loadPlatformName();
loadStats();
loadFeaturedMembers();
loadRecentProjects();
loadUpcomingEvents();
loadGallery();
