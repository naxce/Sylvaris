import importlib.util
import os
import tempfile
import unittest

spec = importlib.util.spec_from_file_location("sync", os.path.join(os.path.dirname(__file__), "..", "shell", "helpers", "sync.py"))
sync = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sync)


class SyncTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.home = self.tmp.name

    def tearDown(self):
        self.tmp.cleanup()

    def test_write_and_skip(self):
        os.makedirs(os.path.join(self.home, "kitty"))
        ops = [
            {"op": "write", "path": os.path.join(self.home, "kitty", "sylvaris.conf"), "content": "a", "needs": os.path.join(self.home, "kitty")},
            {"op": "write", "path": os.path.join(self.home, "zed", "themes", "s.json"), "content": "b", "needs": os.path.join(self.home, "zed")},
        ]
        ops[0]["target"] = "kitty"
        res = sync.apply(ops)
        self.assertEqual(res[0]["status"], "written")
        self.assertEqual(res[0]["target"], "kitty")
        self.assertTrue(res[1]["status"].startswith("skipped"))
        self.assertEqual(res[1]["target"], "")
        self.assertEqual(sync.apply(ops[:1])[0]["status"], "same")

    def test_lines_are_added_once_and_created_when_missing(self):
        conf = os.path.join(self.home, "kitty.conf")
        with open(conf, "w") as f:
            f.write("font_size 12")
        self.assertEqual(sync.ensure_line(conf, "include sylvaris.conf"), "added")
        self.assertEqual(sync.ensure_line(conf, "include sylvaris.conf"), "ok")
        with open(conf) as f:
            self.assertEqual(f.read(), "font_size 12\ninclude sylvaris.conf\n")
        gtk = os.path.join(self.home, "gtk-3.0", "gtk.css")
        self.assertEqual(sync.ensure_line(gtk, "@import 'sylvaris.css';"), "created")

    def test_firefox_profiles(self):
        root = os.path.join(self.home, ".mozilla", "firefox")
        os.makedirs(os.path.join(root, "abc.default"))
        with open(os.path.join(root, "profiles.ini"), "w") as f:
            f.write("[Profile0]\nName=default\nIsRelative=1\nPath=abc.default\n")
        chrome = os.path.join(root, "abc.default", "chrome")
        os.makedirs(chrome)
        with open(os.path.join(chrome, "userChrome.css"), "w") as f:
            f.write("#nav-bar { border: 0 }\n")
        res = sync.apply([{"op": "firefox", "content": ":root{}", "roots": [root]}])
        self.assertEqual([r["status"] for r in res], ["written", "added", "created"])
        with open(os.path.join(chrome, "userChrome.css")) as f:
            self.assertTrue(f.read().startswith('@import "sylvaris.css";\n'))


if __name__ == "__main__":
    unittest.main()
