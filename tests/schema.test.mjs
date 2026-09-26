import { test } from "node:test"
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import { schema } from "../shell/lib/schema.mjs"

test("nix/schema.json lists every setting the shell knows, so Home Manager has an option for each", () => {
    const committed = JSON.parse(readFileSync(new URL("../nix/schema.json", import.meta.url)))
    assert.deepEqual(committed, schema(), "run: node -e 'import(\"./shell/lib/schema.mjs\").then(s => console.log(JSON.stringify(s.schema(), null, 2)))' > nix/schema.json")
})
