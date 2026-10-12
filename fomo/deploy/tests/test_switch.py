import importlib.util
from pathlib import Path
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("switch", Path(__file__).resolve().parents[1] / "switch.py")
switcher = importlib.util.module_from_spec(spec)
spec.loader.exec_module(switcher)


class SwitchTests(unittest.TestCase):
    def test_unhealthy_candidate_never_changes_routing(self):
        with patch.object(switcher, "health", return_value={"ok": False, "color": "green"}), patch.object(switcher.subprocess, "run") as run:
            with self.assertRaises(RuntimeError): switcher.switch("green", True)
            run.assert_not_called()

    def test_real_oauth_check_required(self):
        with patch.object(switcher, "health", return_value={"ok": True, "color": "green", "auth_mode": "hybrid"}), patch.object(switcher.subprocess, "run") as run:
            with self.assertRaises(RuntimeError): switcher.switch("green")
            run.assert_not_called()

    def test_successful_switch(self):
        state = {"ok": True, "color": "green", "auth_mode": "hybrid"}
        with patch.object(switcher, "health", return_value=state), patch.object(switcher.subprocess, "run") as run:
            switcher.switch("green", True)
            self.assertEqual(run.call_count, 1)
            self.assertIn("nginx -t", run.call_args.args[0][-1])

    def test_verification_failure_restores_previous_route(self):
        with patch.object(switcher, "health", side_effect=[{"ok": True, "color": "green", "auth_mode": "hybrid"}, OSError("proxy unavailable")]), patch.object(switcher.subprocess, "run") as run:
            with self.assertRaises(RuntimeError): switcher.switch("green", True)
            self.assertEqual(run.call_count, 2)
            self.assertIn("fomo-previous.conf", run.call_args.args[0][-1])
