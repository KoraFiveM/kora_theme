(() => {
  "use strict";

  const picker = document.getElementById("picker");
  const presets = document.getElementById("presets");
  const custom = document.getElementById("custom-colour");
  const customValue = document.getElementById("custom-value");
  const error = document.getElementById("error");
  let selected = null;

  // Match every other first-party NUI: author at 1920x1080 and scale the
  // complete surface in both directions for the player's native resolution.
  const scaleNui = () => {
    const scale = Math.min(2, Math.max(0.5, Math.min(window.innerWidth / 1920, window.innerHeight / 1080)));
    document.body.style.width = `${window.innerWidth / scale}px`;
    document.body.style.height = `${window.innerHeight / scale}px`;
    document.body.style.transform = `scale(${scale})`;
    document.body.style.transformOrigin = "top left";
  };
  scaleNui();
  window.addEventListener("resize", scaleNui);

  const resource = typeof GetParentResourceName === "function" ? GetParentResourceName() : "kora_theme";
  const post = async (name, data = {}) => {
    const response = await fetch(`https://${resource}/${name}`, {
      method: "POST",
      headers: { "Content-Type": "application/json; charset=UTF-8" },
      body: JSON.stringify(data),
    });
    return response.json();
  };

  const markSelected = () => {
    for (const button of presets.children) {
      button.classList.toggle("selected", button.dataset.colour === selected);
    }
  };

  const render = (state) => {
    if (!state || typeof state !== "object") return;
    selected = state.selected || null;
    presets.replaceChildren();
    for (const preset of state.presets || []) {
      const button = document.createElement("button");
      button.type = "button";
      button.className = "swatch";
      button.title = preset.label;
      button.dataset.colour = preset.colour;
      button.style.setProperty("--swatch", preset.colour);
      button.setAttribute("aria-label", preset.label);
      button.addEventListener("click", () => void choose(preset.colour));
      presets.append(button);
    }
    const preview = selected || state.default;
    if (preview) {
      custom.value = preview;
      customValue.value = preview;
    }
    markSelected();
  };

  const choose = async (colour) => {
    error.textContent = "";
    try {
      const result = await post("kora_theme:set", { colour });
      if (!result.ok) throw new Error(result.message || "Could not save that colour.");
      render(result.state);
    } catch (reason) {
      error.textContent = reason instanceof Error ? reason.message : "Could not save that colour.";
    }
  };

  const close = async () => {
    picker.classList.remove("open");
    picker.setAttribute("aria-hidden", "true");
    try { await post("kora_theme:close"); } catch (_) { /* resource may be stopping */ }
  };

  window.addEventListener("message", (event) => {
    if (event.origin !== "nui://game") return;
    if (event.data?.action === "kora_theme:open") {
      render(event.data.data);
      picker.classList.add("open");
      picker.setAttribute("aria-hidden", "false");
      document.getElementById("close").focus();
    } else if (event.data?.action === "kora_theme:close") {
      picker.classList.remove("open");
      picker.setAttribute("aria-hidden", "true");
    } else if (event.data?.action === "kora_theme:state") {
      render(event.data.data);
    }
  });

  custom.addEventListener("input", () => { customValue.value = custom.value.toUpperCase(); });
  document.getElementById("apply").addEventListener("click", () => void choose(custom.value));
  document.getElementById("reset").addEventListener("click", () => void choose(null));
  document.getElementById("close").addEventListener("click", () => void close());
  document.getElementById("done").addEventListener("click", () => void close());
  document.addEventListener("keydown", (event) => { if (event.key === "Escape") void close(); });
})();
