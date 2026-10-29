// Keep the source's query intact. tldr accepts the address after its host.
export function summaryAddress(address, origin = "https://tldr.tf") {
  try {
    const source = new URL(address);
    if (!["http:", "https:"].includes(source.protocol) || source.username || source.password) {
      return `${origin}/`;
    }
    source.hash = "";
    return source.origin === origin ? source.href : `${origin}/${source.href}`;
  } catch {
    return `${origin}/`;
  }
}
