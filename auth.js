// =====================================================================
// Authentication module
// Wraps Supabase Auth: register, login, logout, password reset,
// session retrieval, and a simple route guard.
// =====================================================================

import { supabase } from './supabase-client.js';

/**
 * Register a new member.
 * Duplicate email/username are caught via the `profiles` unique
 * constraints + the auth.users unique email constraint; we surface a
 * clean error instead of the raw Postgres error (Section 39/45).
 */
export async function registerUser({ email, password, fullName, username }) {
  // Pre-check username availability so we can give a friendly error
  // before hitting auth.users (RLS still enforces this server-side).
  const { data: existing, error: lookupError } = await supabase
    .from('profiles')
    .select('id')
    .eq('username', username)
    .maybeSingle();

  if (lookupError) {
    return { error: 'Could not verify username availability. Please try again.' };
  }
  if (existing) {
    return { error: 'That username is already taken.' };
  }

  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      data: { full_name: fullName, username }, // consumed by handle_new_user() trigger
      emailRedirectTo: new URL('public-login.html', window.location.href).href,
    },
  });

  if (error) {
    if (error.message.toLowerCase().includes('already registered')) {
      return { error: 'An account with that email already exists.' };
    }
    return { error: 'Registration failed. Please check your details and try again.' };
  }

  return { data };
}

export async function loginUser({ email, password }) {
  const { data, error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) {
    return { error: 'Incorrect email or password.' };
  }
  return { data };
}

export async function logoutUser() {
  const { error } = await supabase.auth.signOut();
  if (error) return { error: 'Could not log out. Please try again.' };
  return { success: true };
}

export async function requestPasswordReset(email) {
  const { error } = await supabase.auth.resetPasswordForEmail(email, {
    redirectTo: new URL('public-login.html', window.location.href).href,
  });
  if (error) return { error: 'Could not send reset email. Please try again.' };
  return { success: true };
}

export async function getCurrentSession() {
  const { data, error } = await supabase.auth.getSession();
  if (error) return null;
  return data.session;
}

export async function getCurrentProfile() {
  const session = await getCurrentSession();
  if (!session) return null;

  const { data, error } = await supabase
    .from('profiles')
    .select('*')
    .eq('id', session.user.id)
    .single();

  if (error) return null;
  return data;
}

/**
 * Route guard: redirect to login if unauthenticated, or to a
 * "not authorized" page if the profile's role isn't in allowedRoles.
 * Use on every member/admin page — never trust the frontend alone,
 * RLS is the real enforcement layer (Section 29).
 */
export async function requireRole(allowedRoles = []) {
  const profile = await getCurrentProfile();
  if (!profile) {
    window.location.href = 'public-login.html';
    return null;
  }
  if (profile.is_suspended) {
    window.location.href = 'public-suspended.html';
    return null;
  }
  if (allowedRoles.length && !allowedRoles.includes(profile.role)) {
    window.location.href = 'public-not-authorized.html';
    return null;
  }
  return profile;
}
