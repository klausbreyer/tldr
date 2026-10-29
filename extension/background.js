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
function openSummary(tab, address) {
  if (!Number.isInteger(tab?.id) || tab.id < 0) return;
  const query = new URLSearchParams({ address: address || "" });
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
  if (info.menuItemId === "summarize-link") openSummary(tab, info.linkUrl);
});
