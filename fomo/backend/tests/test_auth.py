import unittest
from unittest.mock import Mock, patch
from fastapi import HTTPException
from sqlalchemy import create_engine, select, event
from sqlalchemy.orm import Session
from app.db import Base
from app.models import AuthIdentity, User, UserSession
from app.routes import auth
from app.schemas import AccountRegister, AccountLogin, GoogleAuthIn, SupabaseAuthIn
from app import supabase_auth

CLAIMS = {"id": "supabase-user-1", "email": "person@gmail.com", "email_confirmed_at": "2026-01-01",
          "identities": [{"provider": "google", "identity_data": {"sub": "google-1"}}]}


class AuthTests(unittest.TestCase):
    def setUp(self):
        self.engine = create_engine("sqlite://")
        event.listen(self.engine, "connect", lambda db, _: db.execute("PRAGMA foreign_keys=ON"))
        Base.metadata.create_all(self.engine)
        self.db = Session(self.engine)
        self.mode = patch.object(auth, "AUTH_MODE", "hybrid")
        self.mode.start()
        self.verifier = patch.object(auth, "verify_google_session", return_value=CLAIMS.copy())
        self.verifier.start()

    def tearDown(self):
        self.verifier.stop()
        self.mode.stop()
        self.db.close()
        self.engine.dispose()

    def google(self, **kwargs):
        return auth.login_with_supabase(SupabaseAuthIn(access_token="test", **kwargs), None, self.db)

    def test_google_creates_and_reuses_user(self):
        first = self.google()
        second = self.google()
        self.assertEqual(first.user_id, second.user_id)
        self.assertNotEqual(first.token, second.token)
        self.assertEqual(len(self.db.scalars(select(User)).all()), 1)
        self.assertIsNone(self.db.get(User, first.user_id).password_hash)
        self.assertEqual(auth.get_user_id(authorization="Bearer " + first.token, db=self.db), first.user_id)

    def test_legacy_google_survives_blue(self):
        claims = {"sub": "old-google", "email": "old@gmail.com", "email_verified": True}
        with patch.object(auth, "AUTH_MODE", "password"), patch.object(auth, "GOOGLE_CLIENT_ID", "our-client"), patch.object(auth.google_id_token, "verify_oauth2_token", return_value=claims) as verifier:
            account = auth.legacy_google_login(GoogleAuthIn(id_token="signed-token"), self.db)
            self.assertEqual(verifier.call_args.args[2], "our-client")
            self.assertEqual(self.db.get(User, account.user_id).google_sub, "old-google")

    def test_legacy_access_token_audience_rejected(self):
        response = Mock(status_code=200)
        response.json.return_value = {"aud": "another-app", "sub": "attacker", "email": "a@gmail.com", "email_verified": "true"}
        with patch.object(auth, "GOOGLE_CLIENT_ID", "our-client"), patch.object(auth.requests, "get", return_value=response):
            with self.assertRaises(HTTPException) as error:
                auth.legacy_google_login(GoogleAuthIn(access_token="other-token"), self.db)
            self.assertEqual(error.exception.status_code, 401)
        self.assertIsNone(self.db.scalar(select(User)))

    def test_google_only_retires_legacy_route(self):
        with patch.object(auth, "AUTH_MODE", "google"), self.assertRaises(HTTPException) as error:
            auth.legacy_google_login(GoogleAuthIn(id_token="old-token"), self.db)
        self.assertEqual(error.exception.status_code, 410)

    def test_password_blue_blocks_google(self):
        with patch.object(auth, "AUTH_MODE", "password"), self.assertRaises(HTTPException) as error:
            self.google()
        self.assertEqual(error.exception.status_code, 403)

    def test_google_mode_blocks_password_but_keeps_sessions(self):
        registered = auth.register_account(AccountRegister(username="tester", password="password123"), self.db)
        with patch.object(auth, "AUTH_MODE", "google"):
            for action, payload in [(auth.login_account, AccountLogin(username="tester", password="password123")),
                                    (auth.register_account, AccountRegister(username="other", password="password123"))]:
                with self.assertRaises(HTTPException) as error: action(payload, self.db)
                self.assertEqual(error.exception.status_code, 403)
            self.assertEqual(auth.get_user_id("Bearer " + registered.token, self.db), registered.user_id)

    def test_never_links_by_email(self):
        self.db.add(User(id="legacy", username=CLAIMS["email"], password_hash="saved"))
        self.db.commit()
        with self.assertRaises(HTTPException) as error: self.google()
        self.assertEqual(error.exception.status_code, 409)
        self.assertIsNone(self.db.scalar(select(AuthIdentity)))

    def test_authenticated_link_keeps_existing_id(self):
        old = auth.register_account(AccountRegister(username="tester", password="password123"), self.db)
        linked = auth.login_with_supabase(SupabaseAuthIn(access_token="test", link_account=True), "Bearer " + old.token, self.db)
        self.assertEqual(linked.user_id, old.user_id)
        self.assertEqual(self.google().user_id, old.user_id)

    def test_link_requires_fomo_session(self):
        with self.assertRaises(HTTPException) as error: self.google(link_account=True)
        self.assertEqual(error.exception.status_code, 401)

    def test_identity_cannot_be_stolen(self):
        self.google()
        old = auth.register_account(AccountRegister(username="tester", password="password123"), self.db)
        with self.assertRaises(HTTPException) as error:
            auth.login_with_supabase(SupabaseAuthIn(access_token="test", link_account=True), "Bearer " + old.token, self.db)
        self.assertEqual(error.exception.status_code, 409)

    def test_logout_revokes_session(self):
        account = self.google()
        auth.logout("Bearer " + account.token, self.db)
        self.assertIsNone(self.db.get(UserSession, account.token))

    def test_invalid_provider_creates_no_user(self):
        with patch.object(auth, "verify_google_session", side_effect=HTTPException(401, "invalid")):
            with self.assertRaises(HTTPException): self.google()
        self.assertIsNone(self.db.scalar(select(User)))

    def test_migration_is_additive_and_repeatable(self):
        from app.migrate_auth import migrate
        old = auth.register_account(AccountRegister(username="tester", password="password123"), self.db)
        AuthIdentity.__table__.drop(self.engine)
        with patch("app.migrate_auth.engine", self.engine): migrate(); migrate()
        self.assertEqual(self.db.get(User, old.user_id).username, "tester")
        self.assertIsNotNone(self.db.get(UserSession, old.token))


class VerificationTests(unittest.TestCase):
    def verify(self, status=200, claims=None, exception=None):
        response = Mock(status_code=status)
        response.json.return_value = CLAIMS if claims is None else claims
        with patch.object(supabase_auth, "SUPABASE_URL", "https://project.supabase.co"), \
             patch.object(supabase_auth, "SUPABASE_PUBLISHABLE_KEY", "public-key"), \
             patch.object(supabase_auth.requests, "get", return_value=response, side_effect=exception) as request:
            result = supabase_auth.verify_google_session("token")
            self.assertEqual(request.call_args.args[0], "https://project.supabase.co/auth/v1/user")
            self.assertFalse(request.call_args.kwargs["allow_redirects"])
            return result

    def test_valid_google(self): self.assertEqual(self.verify()["id"], CLAIMS["id"])

    def test_invalid_token(self):
        with self.assertRaises(HTTPException) as error: self.verify(status=401)
        self.assertEqual(error.exception.status_code, 401)

    def test_unverified_email(self):
        with self.assertRaises(HTTPException): self.verify(claims={**CLAIMS, "email_confirmed_at": None})

    def test_other_provider_rejected(self):
        with self.assertRaises(HTTPException): self.verify(claims={**CLAIMS, "identities": [{"provider": "email"}]})

    def test_provider_timeout(self):
        import requests
        with self.assertRaises(HTTPException) as error: self.verify(exception=requests.Timeout())
        self.assertEqual(error.exception.status_code, 503)


if __name__ == "__main__": unittest.main()
