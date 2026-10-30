import { summaryAddress } from "./address.mjs";
import { origin } from "./origin.mjs";

const address = new URLSearchParams(location.search).get("address");
document.getElementById("tldr").src = summaryAddress(address, origin);
