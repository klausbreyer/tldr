chrome.runtime.onInstalled.addListener(async () => {
  await chrome.contextMenus.removeAll();
  chrome.contextMenus.create({
    id: "summarize-link",
    title: chrome.i18n.getMessage("summarizeLink"),
    contexts: ["link"],
    targetUrlPatterns: ["http://*/*", "https://*/*"],
  });
});

// A tab-specific path carries the address without storage or a background cache.
// Open immediately: Chrome requires the original click's user gesture.
function openSummary(tab, address, page = tab?.url) {
  if (!Number.isInteger(tab?.id) || tab.id < 0) return;
  const query = new URLSearchParams({ address: address || "", page: page || "" });
  const configured = chrome.sidePanel.setOptions({
    tabId: tab.id,
    path: `panel.html?${query}`,
    enabled: true,
  });
  const opened = chrome.sidePanel.open({ tabId: tab.id });
  Promise.all([configured, opened]).catch(console.error);
}

chrome.action.onClicked.addListener((tab) => openSummary(tab, tab.url));
chrome.contextMenus.onClicked.addListener((info, tab) => {
  if (info.menuItemId === "summarize-link") openSummary(tab, info.linkUrl, tab?.url || info.pageUrl);
});

// The panel path keeps its opening page through service-worker restarts.
// Ignore fragments, reloads, and navigation inside embedded frames.
async function closeAfterNavigation({ tabId, frameId, url }) {
  if (frameId !== 0) return;
  try {
    const { enabled, path } = await chrome.sidePanel.getOptions({ tabId });
    const page = new URLSearchParams(path?.split("?")[1]).get("page");
    if (enabled && page && page.split("#")[0] !== url.split("#")[0]) {
      await chrome.sidePanel.setOptions({ tabId, enabled: false });
    }
  } catch (error) {
    // A tab can close while the panel options are being read.
    console.error(error);
  }
}

chrome.webNavigation.onCommitted.addListener(closeAfterNavigation);
chrome.webNavigation.onHistoryStateUpdated.addListener(closeAfterNavigation);
