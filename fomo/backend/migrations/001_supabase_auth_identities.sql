-- Additive: old releases continue using users and user_sessions unchanged.
CREATE TABLE IF NOT EXISTS public.auth_identities (
    id VARCHAR PRIMARY KEY,
    provider VARCHAR NOT NULL,
    subject VARCHAR NOT NULL,
    user_id VARCHAR NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_auth_identity UNIQUE (provider, subject),
    CONSTRAINT uq_auth_user_provider UNIQUE (provider, user_id)
);
CREATE INDEX IF NOT EXISTS ix_auth_identities_user_id ON public.auth_identities(user_id);
ALTER TABLE public.auth_identities ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.auth_identities FROM anon, authenticated;
