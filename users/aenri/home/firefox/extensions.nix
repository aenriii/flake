let extension = shortId: guid: private_browsing: {
    name = guid;
    value = {
      inherit private_browsing;
      install_url = "https://addons.mozilla.org/en-US/firefox/downloads/latest/${shortId}/latest.xpi";
      installation_mode = "normal_installed"; 
    };
  };
in
builtins.listToAttrs [
  # ublock origin, gold standard adblocker & anti-tracker
  (extension "ublock-origin" "uBlock0@raymondhill.net" true)
  # canvas blocker, anti-fingerprinting for HTML5 canvases
  (extension "canvasblocker" "CanvasBlocker@kkapsner.de" true)
  # clearurls, scrub tracking from urls
  (extension "clearurls" "{74145f27-f039-47ce-a470-a662b129930a}" true)
  # skip redirect, attempts to get the redirect url from redirect links
  (extension "skip-redirect" "skipredirect@sblask" true)
  # behave, alerts you when a site attempts to ping local ips
  (extension "behave" "{17c7f098-dbb8-4f15-ad39-8b578da80f7e}" true)
  # temporary containers, single-use multi-account containers
  (extension "temporary-containers" "{c607c8df-14a7-4f28-894f-29e8722976af}" true)
  # multi-account containers!
  (extension "multi-account-containers" "@testpilot-containers" false)
  # bitwarden, my preferred password manager
  (extension "bitwarden-password-manager" "{446900e4-71c2-419f-a6a7-df9c091e268b}" true)
]