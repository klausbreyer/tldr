import { cp, mkdir, readFile, writeFile } from "node:fs/promises";
import { createHash } from "node:crypto";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";

// Make a separate unpacked copy for a local server. Never alter the release files.
const [destination, base = "https://tldr.tf"] = process.argv.slice(2);
if (!destination) throw new Error("Usage: node scripts/prepare-extension.mjs <new-directory> [origin]");
const origin = new URL(base);
if (!["http:", "https:"].includes(origin.protocol) || origin.href !== `${origin.origin}/`) {
  throw new Error("Use an http or https origin without a path, query, or credentials.");
}
if (origin.protocol === "http:" && origin.hostname !== "localhost") {
  throw new Error("Embedded sessions require HTTPS, except on localhost.");
}
const source = fileURLToPath(new URL("../extension/", import.meta.url));
const output = resolve(destination);
await mkdir(output); // Refuse to overwrite an existing directory.
await cp(source, output, { recursive: true });
const manifest = JSON.parse(await readFile(`${output}/manifest.json`, "utf8"));
manifest.host_permissions = [`${origin.origin}/*`];
manifest.content_security_policy.extension_pages = `script-src 'self'; object-src 'none'; frame-src ${origin.origin};`;
await writeFile(`${output}/manifest.json`, JSON.stringify(manifest, null, 2) + "\n");
await writeFile(`${output}/origin.mjs`, `export const origin = ${JSON.stringify(origin.origin)};\n`);
const digest = createHash("sha256").update(Buffer.from(manifest.key, "base64")).digest("hex").slice(0, 32);
const id = [...digest].map((digit) => String.fromCharCode(97 + parseInt(digit, 16))).join("");
console.log(`Extension: ${output}\nCHROME_EXTENSION_ID=${id}`);
