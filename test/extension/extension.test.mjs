import assert from "node:assert/strict";
import { test } from "node:test";
import { readFile } from "node:fs/promises";
import vm from "node:vm";
import { summaryAddress } from "../../extension/address.mjs";

test("web links keep their query and encoding, without a fragment", () => {
  assert.equal(
    summaryAddress("https://example.com/a%20b?x=1&next=https%3A%2F%2Fexample.org#part"),
    "https://tldr.tf/https://example.com/a%20b?x=1&next=https%3A%2F%2Fexample.org",
  );
});

test("YouTube links use the same prefix, without an a parameter", () => {
  assert.equal(
    summaryAddress("https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=30"),
    "https://tldr.tf/https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=30",
  );
});

test("unsupported pages and addresses with credentials open the empty page", () => {
  for (const address of [undefined, "", "chrome://extensions", "file:///tmp/a", "javascript:alert(1)", "https://user:pass@example.com"]) {
    assert.equal(summaryAddress(address), "https://tldr.tf/");
  }
});

test("a tldr page is not wrapped again", () => {
  assert.equal(summaryAddress("https://tldr.tf/https://example.com"), "https://tldr.tf/https://example.com");
});

test("local preview uses its own origin", () => {
  assert.equal(summaryAddress("https://example.com", "http://localhost:4441"), "http://localhost:4441/https://example.com/");
});

test("icon and link menu open separate tab panels, within the user gesture", async () => {
  const calls = [];
  const listeners = {};
  const event = (name) => ({ addListener: (fn) => { listeners[name] = fn; } });
  const chrome = {
    runtime: { onInstalled: event("install") },
    i18n: { getMessage: () => "Summarize with tldr" },
    contextMenus: {
      onClicked: event("menu"),
      removeAll: async () => {},
      create: (options) => calls.push(["menu", options]),
    },
    action: { onClicked: event("action") },
    webNavigation: { onCommitted: event("navigate"), onHistoryStateUpdated: event("history") },
    sidePanel: {
      // An unresolved promise checks that opening does not wait for an API round trip.
      setOptions: (options) => { calls.push(["options", options]); return new Promise(() => {}); },
      open: (options) => { calls.push(["open", options]); return Promise.resolve(); },
    },
  };
  const code = await readFile(new URL("../../extension/background.js", import.meta.url), "utf8");
  vm.runInNewContext(code, { chrome, URLSearchParams, console });
  await listeners.install();
  assert.deepEqual(Array.from(calls[0][1].targetUrlPatterns), ["http://*/*", "https://*/*"]);
  calls.length = 0;
  listeners.action({ id: 12, url: "https://example.com/?x=1&y=2" });
  listeners.menu({ menuItemId: "summarize-link", linkUrl: "https://youtu.be/dQw4w9WgXcQ" }, { id: 34 });
  assert.equal(calls[0][1].tabId, 12);
  assert.equal(new URLSearchParams(calls[0][1].path.split("?")[1]).get("address"), "https://example.com/?x=1&y=2");
  assert.equal(calls[1][0], "open");
  assert.equal(calls[1][1].tabId, 12);
  assert.equal(calls[2][1].tabId, 34);
  assert.equal(new URLSearchParams(calls[2][1].path.split("?")[1]).get("address"), "https://youtu.be/dQw4w9WgXcQ");
  assert.equal(calls[3][1].tabId, 34);
});

async function navigationHarness(options = new Map()) {
  const listeners = {};
  const changes = [];
  const event = (name) => ({ addListener: (fn) => { listeners[name] = fn; } });
  const chrome = {
    runtime: { onInstalled: event("install") },
    action: { onClicked: event("action") },
    contextMenus: { onClicked: event("menu") },
    webNavigation: { onCommitted: event("navigate"), onHistoryStateUpdated: event("history") },
    sidePanel: {
      getOptions: async ({ tabId }) => options.get(tabId) ?? { enabled: true, path: "panel.html" },
      setOptions: async (value) => {
        changes.push(value);
        options.set(value.tabId, { ...options.get(value.tabId), ...value });
      },
      open: async () => {},
    },
  };
  const code = await readFile(new URL("../../extension/background.js", import.meta.url), "utf8");
  const restart = () => vm.runInNewContext(code, { chrome, URLSearchParams, console });
  restart();
  return { listeners, changes, restart };
}

test("leaving a page closes only its panel, including after a worker restart", async () => {
  const { listeners, changes, restart } = await navigationHarness();
  listeners.action({ id: 1, url: "https://example.com/article#intro" });
  listeners.action({ id: 2, url: "https://example.org/" });
  changes.length = 0;
  restart();
  await listeners.navigate({ tabId: 1, frameId: 0, url: "https://example.net/" });
  assert.equal(changes.length, 1);
  assert.equal(changes[0].tabId, 1);
  assert.equal(changes[0].enabled, false);
  changes.length = 0;
  await listeners.navigate({ tabId: 1, frameId: 0, url: "https://example.com/article" });
  await listeners.navigate({ tabId: 3, frameId: 0, url: "https://example.net/" });
  assert.equal(changes.length, 0, "returning or unrelated tabs must not open or change panels");
});

test("reloads, fragments and subframes keep the panel open", async () => {
  const { listeners, changes } = await navigationHarness();
  listeners.action({ id: 1, url: "https://example.com/article#intro" });
  changes.length = 0;
  await listeners.navigate({ tabId: 1, frameId: 0, url: "https://example.com/article#intro" });
  await listeners.history({ tabId: 1, frameId: 0, url: "https://example.com/article#end" });
  await listeners.navigate({ tabId: 1, frameId: 3, url: "https://ads.example/" });
  assert.equal(changes.length, 0);
});

test("a YouTube history navigation closes the panel and a click opens it again", async () => {
  const { listeners, changes } = await navigationHarness();
  listeners.action({ id: 1, url: "https://www.youtube.com/watch?v=first" });
  changes.length = 0;
  await listeners.history({ tabId: 1, frameId: 0, url: "https://www.youtube.com/watch?v=second" });
  assert.equal(changes[0].enabled, false);
  listeners.action({ id: 1, url: "https://www.youtube.com/watch?v=second" });
  assert.equal(changes[1].enabled, true);
  await listeners.history({ tabId: 1, frameId: 0, url: "https://www.youtube.com/watch?v=second" });
  assert.equal(changes.length, 2);
});

test("a link summary belongs to the page that opened it, not the link target", async () => {
  const { listeners, changes } = await navigationHarness();
  listeners.menu({ menuItemId: "summarize-link", pageUrl: "https://example.com/", linkUrl: "https://example.org/" }, { id: 1 });
  changes.length = 0;
  await listeners.navigate({ tabId: 1, frameId: 0, url: "https://example.com/" });
  assert.equal(changes.length, 0);
  await listeners.navigate({ tabId: 1, frameId: 0, url: "https://example.org/" });
  assert.equal(changes[0].enabled, false);
});
