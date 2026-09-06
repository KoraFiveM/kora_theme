(() => {
  "use strict";

  const tokenName = /^[a-z][a-z0-9-]{0,63}$/;
  const initialRetryDelay = 250;
  const initialRetryCount = 40;

  function applyTokens(tokens) {
    if (!tokens || typeof tokens !== "object" || Array.isArray(tokens)) return;
    const root = document.documentElement.style;
    for (const [key, value] of Object.entries(tokens)) {
      if (!tokenName.test(key) || typeof value !== "string" || value.length > 160) continue;
      root.setProperty(`--${key}`, value);
    }
  }

  async function loadTokens(reportFailure = true) {
    if (typeof window.GetParentResourceName !== "function") return false;
    try {
      const response = await fetch(`https://${window.GetParentResourceName()}/qbtheme:ready`, {
        method: "POST",
        headers: { "Content-Type": "application/json; charset=UTF-8" },
        body: "{}",
      });
      if (!response.ok) return false;
      applyTokens(await response.json());
      return true;
    } catch (error) {
      if (reportFailure) console.error("[qbtheme] could not load runtime tokens", error);
      return false;
    }
  }

  // A loadscreen's browser is created before its resource has necessarily
  // registered the raw qbtheme:ready NUI callback. Retry quietly during that
  // short startup window so it receives configured tokens rather than keeping
  // theme.css's static fallback palette.
  function loadInitialTokens(remaining = initialRetryCount) {
    void loadTokens(false).then((loaded) => {
      if (!loaded && remaining > 0) {
        window.setTimeout(() => loadInitialTokens(remaining - 1), initialRetryDelay);
      }
    });
  }

  window.addEventListener("message", (event) => {
    if (event.origin !== "nui://game") return;
    if (event.data?.action === "qbtheme:tokens") applyTokens(event.data.data);
  });

  window.QBTheme = Object.freeze({ applyTokens, refresh: () => loadTokens() });
  loadInitialTokens();
})();
