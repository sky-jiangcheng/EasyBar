/* Minimal i18n switcher: no build step, no dependencies.
 * Blocks marked [data-lang-block="zh-CN"|"en"] are toggled;
 * choice persists in localStorage and is shareable via ?lang=zh|en. */
(function () {
  "use strict";

  var STORAGE_KEY = "easybar-lang";
  var ZH = "zh-CN";
  var EN = "en";

  function short(lang) {
    return lang === ZH ? "zh" : "en";
  }

  function normalize(value) {
    if (!value) return null;
    var v = String(value).toLowerCase();
    if (v.indexOf("zh") === 0) return ZH;
    if (v.indexOf("en") === 0) return EN;
    return null;
  }

  function fromQuery() {
    try {
      return normalize(new URLSearchParams(window.location.search).get("lang"));
    } catch (e) {
      return null;
    }
  }

  function readStored() {
    try {
      return normalize(window.localStorage.getItem(STORAGE_KEY));
    } catch (e) {
      return null;
    }
  }

  function writeStored(lang) {
    try {
      window.localStorage.setItem(STORAGE_KEY, lang);
    } catch (e) {
      /* private mode / blocked storage: fall back to in-memory only */
    }
  }

  function detect() {
    var nav =
      (navigator.languages && navigator.languages[0]) ||
      navigator.language ||
      EN;
    return normalize(nav) || EN;
  }

  function applyTitle(lang) {
    var el = document.head ? document.head.getElementsByTagName("title")[0] : null;
    if (!el) return;
    var value = el.getAttribute("data-title-" + lang) || el.getAttribute("data-title-" + short(lang));
    if (value) document.title = value;
  }

  function syncUrl(lang) {
    try {
      var url = new URL(window.location.href);
      if (url.protocol === "file:") return;
      url.searchParams.set("lang", short(lang));
      window.history.replaceState(null, "", url.toString());
    } catch (e) {
      /* ignore */
    }
  }

  function apply(lang) {
    document.documentElement.lang = lang;

    var blocks = document.querySelectorAll("[data-lang-block]");
    for (var i = 0; i < blocks.length; i++) {
      blocks[i].hidden = blocks[i].getAttribute("data-lang-block") !== lang;
    }

    var buttons = document.querySelectorAll("[data-lang-switch] button");
    for (var j = 0; j < buttons.length; j++) {
      buttons[j].setAttribute(
        "aria-pressed",
        buttons[j].getAttribute("data-lang") === lang ? "true" : "false"
      );
    }

    applyTitle(lang);
  }

  function init() {
    var lang = fromQuery() || readStored() || detect();
    apply(lang);

    var switches = document.querySelectorAll("[data-lang-switch]");
    for (var i = 0; i < switches.length; i++) {
      switches[i].addEventListener("click", function (event) {
        var button = event.target.closest ? event.target.closest("button[data-lang]") : null;
        if (!button) return;
        var next = button.getAttribute("data-lang");
        apply(next);
        writeStored(next);
        syncUrl(next);
      });
    }
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
