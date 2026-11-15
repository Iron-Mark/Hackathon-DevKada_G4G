import base64
import json
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "scripts"))
from check_public_bundle import validate_bundle


class PublicBundleTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.env = self.root / "app" / "assets" / ".env"
        self.env.parent.mkdir(parents=True)
        self.env.write_text("SUPABASE_URL=\nSUPABASE_ANON_KEY=\nHUGGINGFACE_TOKEN=\n")

    def test_empty_preview_and_build_metadata_are_allowed(self):
        (self.root / "app" / ".last_build_id").write_text("a" * 32)
        validate_bundle(self.root)

    def test_missing_runtime_asset_fails(self):
        self.env.unlink()
        with self.assertRaises(ValueError):
            validate_bundle(self.root)

    def test_unexpected_hidden_file_fails(self):
        (self.root / ".unexpected").write_text("not a credential")
        with self.assertRaises(ValueError):
            validate_bundle(self.root)

    def test_server_key_name_fails_even_when_empty(self):
        with self.env.open("a") as handle:
            handle.write("GEMINI_API_KEY=\n")
        with self.assertRaises(ValueError):
            validate_bundle(self.root)

    def test_model_token_is_not_public_configuration(self):
        self.env.write_text("SUPABASE_URL=\nSUPABASE_ANON_KEY=\nHUGGINGFACE_TOKEN=synthetic-test-token\n")
        with self.assertRaises(ValueError):
            validate_bundle(self.root)

    def test_mismatched_client_configuration_fails(self):
        self.env.write_text("SUPABASE_URL=https://example.invalid\nSUPABASE_ANON_KEY=\n")
        with self.assertRaises(ValueError):
            validate_bundle(self.root)

    def test_service_role_cannot_be_mislabeled_as_anonymous(self):
        payload = base64.urlsafe_b64encode(json.dumps({"role": "service_role"}).encode()).decode().rstrip("=")
        self.env.write_text(f"SUPABASE_URL=https://example.invalid\nSUPABASE_ANON_KEY=header.{payload}.synthetic\n")
        with self.assertRaises(ValueError):
            validate_bundle(self.root)

    def test_anonymous_public_key_is_allowed(self):
        payload = base64.urlsafe_b64encode(json.dumps({"role": "anon"}).encode()).decode().rstrip("=")
        self.env.write_text(f"SUPABASE_URL=https://example.invalid\nSUPABASE_ANON_KEY=header.{payload}.synthetic\n")
        validate_bundle(self.root)

    def test_publishable_public_key_is_allowed(self):
        self.env.write_text("SUPABASE_URL=https://example.invalid\nSUPABASE_ANON_KEY=sb_publishable_synthetic_public_key\n")
        validate_bundle(self.root)

    def test_unknown_private_key_format_is_rejected(self):
        self.env.write_text("SUPABASE_URL=https://example.invalid\nSUPABASE_ANON_KEY=synthetic-private-provider-token\n")
        with self.assertRaises(ValueError):
            validate_bundle(self.root)

    def test_credential_bearing_or_non_https_urls_are_rejected(self):
        for url in (
            "postgresql://user:synthetic-password@example.invalid/database",
            "https://user:synthetic-password@example.invalid",
            "https://example.invalid?token=synthetic-private-token",
            "https://example.invalid#synthetic-private-token",
            "http://example.invalid",
            "https://example.invalid:synthetic-private-token",
        ):
            with self.subTest(url_kind=url.split(":")[0]):
                self.env.write_text(f"SUPABASE_URL={url}\nSUPABASE_ANON_KEY=sb_publishable_synthetic_public_key\n")
                with self.assertRaises(ValueError):
                    validate_bundle(self.root)

    def test_comments_cannot_hide_accidental_private_configuration(self):
        with self.env.open("a") as handle:
            handle.write("# synthetic-private-provider-token\n")
        with self.assertRaises(ValueError):
            validate_bundle(self.root)

    def test_inline_private_comment_after_anonymous_jwt_is_rejected(self):
        payload = base64.urlsafe_b64encode(json.dumps({"role": "anon"}).encode()).decode().rstrip("=")
        self.env.write_text(f"SUPABASE_URL=https://example.invalid\nSUPABASE_ANON_KEY=header.{payload}.synthetic # synthetic-private-token\n")
        with self.assertRaises(ValueError):
            validate_bundle(self.root)


if __name__ == "__main__":
    unittest.main()
