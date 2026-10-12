-- Apply only if all app data access uses the trusted Python backend DB role.
-- RLS intentionally has no client policies: FOMO sessions are not Supabase JWTs.
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rsvps ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.users, public.user_sessions, public.follows, public.events, public.rsvps
FROM anon, authenticated;
