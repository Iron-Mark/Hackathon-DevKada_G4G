import base64
import json
from pathlib import Path
import os
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "scripts"))
from build_public_web import public_env, run_public_build


class PublicWebBuildTests(unittest.TestCase):
    def test_only_public_pair_is_copied_from_local_file(self):
        source = (
            "# local development configuration\n"
            "SUPABASE_URL=https://example.invalid\n"
            "SUPABASE_ANON_KEY=sb_publishable_synthetic_public_key\n"
            "GEMINI_API_KEY=synthetic-private-gemini\n"
            "HUGGINGFACE_TOKEN=synthetic-private-model-token\n"
            "CLOUD_PS=synthetic-private-provisioning-key\n"
        )
        result = public_env(source, {})
        self.assertEqual(
            result,
            "SUPABASE_URL=https://example.invalid\n"
            "SUPABASE_ANON_KEY=sb_publishable_synthetic_public_key\n"
            "HUGGINGFACE_TOKEN=\n",
        )

    def test_environment_provider_values_are_not_client_values(self):
        result = public_env("", {
            "SUPABASE_URL": "https://example.invalid",
            "SUPABASE_ANON_KEY": "sb_publishable_synthetic_public_key",
            "HUGGINGFACE_TOKEN": "synthetic-private-model-token",
            "GEMINI_API_KEY": "synthetic-private-gemini",
        })
        self.assertNotIn("synthetic-private", result)
        self.assertNotIn("GEMINI_API_KEY", result)

    def test_exported_and_quoted_native_public_values_are_preserved(self):
        result = public_env(
            'export SUPABASE_URL = "https://example.invalid" # native comment\n'
            "export SUPABASE_ANON_KEY='sb_publishable_synthetic_public_key'\n",
            {},
        )
        self.assertEqual(
            result,
            "SUPABASE_URL=https://example.invalid\n"
            "SUPABASE_ANON_KEY=sb_publishable_synthetic_public_key\n"
            "HUGGINGFACE_TOKEN=\n",
        )

    def test_environment_pair_overrides_native_local_values(self):
        self.assertEqual(
            public_env("SUPABASE_URL=https://example.invalid\nSUPABASE_ANON_KEY=sb_publishable_local\n", {
                "SUPABASE_URL": "", "SUPABASE_ANON_KEY": "",
            }),
            "SUPABASE_URL=\nSUPABASE_ANON_KEY=\nHUGGINGFACE_TOKEN=\n",
        )

    def test_mislabeled_service_role_fails_before_any_write(self):
        payload = base64.urlsafe_b64encode(json.dumps({"role": "service_role"}).encode()).decode().rstrip("=")
        with tempfile.TemporaryDirectory() as directory:
            env_path = Path(directory) / ".env"
            original = f"SUPABASE_URL=https://example.invalid\nSUPABASE_ANON_KEY=header.{payload}.synthetic\n"
            env_path.write_text(original)
            with self.assertRaises(ValueError):
                run_public_build([sys.executable, "-c", "raise SystemExit('must not run')"], env_path, {})
            self.assertEqual(env_path.read_text(), original)

    def test_subprocess_gets_no_provider_secrets_and_local_bytes_restored(self):
        for exit_code in (0, 23):
            with self.subTest(exit_code=exit_code), tempfile.TemporaryDirectory() as directory:
                env_path = Path(directory) / ".env"
                original = b"# keep native config\r\nGEMINI_API_KEY=synthetic-private-gemini\r\nHUGGINGFACE_TOKEN=synthetic-private-model-token\r\n"
                env_path.write_bytes(original)
                script = (
                    "import os, pathlib, sys; "
                    "assert 'GEMINI_API_KEY' not in os.environ; "
                    "assert 'HUGGINGFACE_TOKEN' not in os.environ; "
                    "contents=pathlib.Path(sys.argv[1]).read_text(); "
                    "assert 'synthetic-private' not in contents; "
                    "assert contents == 'SUPABASE_URL=\\nSUPABASE_ANON_KEY=\\nHUGGINGFACE_TOKEN=\\n'; "
                    "sys.exit(int(sys.argv[2]))"
                )
                environment = dict(os.environ)
                environment.update({
                    "SUPABASE_URL": "", "SUPABASE_ANON_KEY": "",
                    "GEMINI_API_KEY": "synthetic-private-gemini",
                    "HUGGINGFACE_TOKEN": "synthetic-private-model-token",
                })
                actual = run_public_build([sys.executable, "-c", script, str(env_path), str(exit_code)], env_path, environment)
                self.assertEqual(actual, exit_code)
                self.assertEqual(env_path.read_bytes(), original)

    def test_missing_build_tool_still_restores_local_file(self):
        with tempfile.TemporaryDirectory() as directory:
            env_path = Path(directory) / ".env"
            original = b"HUGGINGFACE_TOKEN=synthetic-private-model-token\n"
            env_path.write_bytes(original)
            with self.assertRaises(OSError):
                run_public_build([str(Path(directory) / "no-such-build-tool")], env_path, {})
            self.assertEqual(env_path.read_bytes(), original)

    def test_no_original_file_leaves_only_safe_public_configuration(self):
        with tempfile.TemporaryDirectory() as directory:
            env_path = Path(directory) / ".env"
            self.assertEqual(run_public_build([sys.executable, "-c", "pass"], env_path, {}), 0)
            self.assertEqual(env_path.read_text(), "SUPABASE_URL=\nSUPABASE_ANON_KEY=\nHUGGINGFACE_TOKEN=\n")

    def test_deployment_and_build_paths_use_the_public_wrapper(self):
        root = Path(__file__).resolve().parents[2]
        build = (root / "build.sh").read_text()
        workflow = (root / ".github/workflows/deploy-pages.yml").read_text()
        self.assertIn("python scripts/build_public_web.py -- flutter build web", build)
        self.assertIn("python scripts/check_public_bundle.py", build)
        self.assertNotIn("${{ secrets.HUGGINGFACE_TOKEN }}", workflow)
        self.assertNotIn("${{ secrets.GEMINI_API_KEY }}", workflow)
        self.assertNotIn("-b stable", build)
        self.assertIn("00b0c91f06209d9e4a41f71b7a512d6eb3b9c694", build)
        docker = (root / "Dockerfile").read_text()
        self.assertIn("python3 scripts/build_public_web.py -- flutter build web", docker)
        self.assertIn("python3 scripts/check_public_bundle.py --app-subdir .", docker)
        ignored = (root / ".dockerignore").read_text().splitlines()
        self.assertIn(".env*", ignored)
        self.assertIn("**/.env*", ignored)


if __name__ == "__main__":
    unittest.main()
