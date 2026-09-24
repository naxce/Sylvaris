import base64
import json
import os
import sys
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "shell", "helpers"))
import diver


def code(**over):
    body = {"v": 1, "url": "https://diver.example", "token": "t" * 64, "salt": "ab" * 32, "key": "11" * 32}
    body.update(over)
    return base64.urlsafe_b64encode(json.dumps(body).encode()).decode().rstrip("=")


class DiverTest(unittest.TestCase):
    def test_pairing_code(self):
        s = diver.decode_code("sylvaris diver pair " + code(url="https://diver.example/"))
        self.assertEqual(s["url"], "https://diver.example")
        self.assertEqual(s["salt"], "ab" * 32)
        with self.assertRaises(ValueError):
            diver.decode_code(code(url="http://diver.example"))
        with self.assertRaises(ValueError):
            diver.decode_code(code(key="11" * 16))
        with self.assertRaises(ValueError):
            diver.decode_code(code(v=2))

    def test_round_trip(self):
        s = diver.decode_code(code())
        data = [{"id": "c", "name": "Życie", "groups": []}]
        blob = diver.encrypt(s, data)
        self.assertTrue(blob.startswith("v1:" + s["salt"] + ":"))
        self.assertEqual(diver.decrypt(s, blob), data)
        with self.assertRaises(PermissionError):
            diver.decrypt(dict(s, salt="cd" * 32), blob)

    def test_reminders_upload(self):
        s = diver.decode_code(code())
        calls = []
        replies = {"GET /api/prefs": (200, {"pushDetails": False, "pushDevices": 2}), "PUT /api/reminders": (200, {"ok": True, "count": 2})}

        def fake(state, method, path, body=None):
            calls.append((method, path, body))
            return replies[method + " " + path]

        real = diver.request
        diver.request = fake
        try:
            items = [
                {"rid": "a@1-0", "at": 1790000000000, "title": "Dentist", "alarm": True},
                {"rid": "b@2-0", "at": 1790000600000, "title": "Pills", "alarm": False},
                {"rid": 5, "at": "soon", "title": None},
            ]
            out = diver.reminders(s, {"items": items})
            self.assertEqual(out, {"ok": True, "sent": True, "count": 2})
            sent = calls[-1][2]["items"]
            self.assertEqual([i["title"] for i in sent], [diver.GENERIC, diver.GENERIC])
            self.assertEqual(sent[0]["alarm"], True)
            replies["GET /api/prefs"] = (200, {"pushDetails": True, "pushDevices": 1})
            diver.reminders(s, {"items": items})
            self.assertEqual(calls[-1][2]["items"][0]["title"], "Dentist")
            replies["GET /api/prefs"] = (200, {"pushDetails": True, "pushDevices": 0})
            calls.clear()
            self.assertEqual(diver.reminders(s, {"items": items}), {"ok": True, "sent": False, "count": 0})
            self.assertEqual([c[0] for c in calls], ["GET"])
            replies["GET /api/prefs"] = (401, None)
            with self.assertRaises(PermissionError):
                diver.reminders(s, {"items": items})
        finally:
            diver.request = real

    def test_tone(self):
        import tempfile
        with tempfile.TemporaryDirectory() as d:
            p = os.path.join(d, "a.wav")
            diver.tone(p)
            with open(p, "rb") as f:
                self.assertEqual(f.read(4), b"RIFF")


if __name__ == "__main__":
    unittest.main()
