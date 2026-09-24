import json
import os
import sys
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "shell", "helpers"))
import airpods


class AirPodsTest(unittest.TestCase):
    def test_battery(self):
        pkt = bytes.fromhex("040004000400" "03" "0201640201" "04015f0101" "0801320401")
        self.assertEqual(airpods.parse(pkt), {"event": "battery", "battery": {"right": {"level": 100, "charging": False}, "left": {"level": 95, "charging": True}}})

    def test_noise_and_awareness(self):
        self.assertEqual(airpods.parse(bytes.fromhex("0400040009000d02000000")), {"event": "noise", "mode": "anc"})
        self.assertEqual(airpods.parse(bytes.fromhex("0400040009000d04000000")), {"event": "noise", "mode": "adaptive"})
        self.assertEqual(airpods.parse(bytes.fromhex("04000400090028 01000000".replace(" ", ""))), {"event": "awareness", "enabled": True})

    def test_ear(self):
        self.assertEqual(airpods.parse(bytes.fromhex("0400040006000001")), {"event": "ear", "primary": "ear", "secondary": "out"})

    def test_unknown_packets_are_ignored(self):
        self.assertIsNone(airpods.parse(bytes.fromhex("0102")))
        self.assertIsNone(airpods.parse(bytes.fromhex("04000400ff000000")))

    def test_commands(self):
        self.assertEqual(airpods.command(json.dumps({"cmd": "noise", "mode": "transparency"})).hex(), "0400040009000d03000000")
        self.assertEqual(airpods.command(json.dumps({"cmd": "awareness", "enabled": False})).hex(), "0400040009002802000000")
        with self.assertRaises(ValueError):
            airpods.command(json.dumps({"cmd": "noise", "mode": "loud"}))


if __name__ == "__main__":
    unittest.main()
