{
  "extensions.autoDisableScopes" = 0;
  "extensions.pocket.enabled" = false;
  "privacy.resistFingerprinting" = true;
  "toolkit.legacyUserProfileCustomizations.stylesheets" = true; # teehee
  # webRTC should be disabled but i need it for my therapy appointments
  # "media.peerconnection.enabled" = false;
  
  # arkenfox - 0000
  "browser.aboutConfig.showWarning" = false;
  # arkenfox - 0100 **Startup**
  "browser.startup.page" = 0;
  "browser.startup.homepage" = "chrome://browser/content/blanktab.html";
  "browser.newtabpage.enabled" = false;
  "browser.newtabpage.activity-stream.showSponsored" = false;
  "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
  "browser.newtabpage.activity-stream.showSponsoredCheckboxes" = false;
  "browser.newtabpage.activity-stream.default.sites" = "";
  # arkenfox - 0200 **Geolocation**
  "geo.provider.ms-windows-location" = false;
  "geo.provider.use_corelocation" = false;
  "geo.provider.use_geoclue" = false;
  # arkenfox - 0300 **Quieter Fox**
  "extensions.getAddons.showPane" = false;
  "extensions.htmlaboutaddons.recommendations.enabled" = false;
  "browser.discovery.enabled" = false;
  "browser.newtabpage.activity-stream.feeds.telemetry" = false;
  "browser.newtabpage.activity-stream.telemetry" = false;
  # redundant, covered by policies 
  # - DisableFirefoxStudies 
  # - DisableFeedbackCommands
  # - CaptivePortal
  # "app.shield.optoutstudies.enabled" = false;
  # "app.normandy.enabled" = false;
  # "app.normandy.api_url" = "";
  # "breakpad.reportURL" = "";
  # "browser.tabs.crashReporting.sendReport" = false;
  # "browser.crashReports.unsubmittedCheck.autoSubmit2" = false;
  # "captivedetect.canonicalURL" = "";
  # "network.captive-portal-service.enabled" = false;
  # "network.connectivity-service.enabled" = false;
  # arkenfox - 0400 **Safe Browsing**
  "browser.safebrowsing.downloads.remote.enabled" = false;
  # arkenfox - 0600 **Block Implicit Outbound**
  "network.prefetch-next" = false;
  "network.dns.disablePrefetch" = true;
  "network.dns.disablePrefetchFromHTTPS" = true;
  "network.http.speculative-parallel-limit" = 0;
  "browser.places.speculativeConnect.enabled" = false;
  # arkenfox - 0700 **DNS/DoH/etc**
  "network.proxy.socks_remote_dns" = true;
  "network.file.disable_unc_paths" = true;
  "network.gio.supported-protocols" = "";
  "network.proxy.failover_direct" = false;
  "network.proxy.allow_bypass" = false;
  "network.trr.mode" = 3;
  "network.trr.uri" = "https://doh.libredns.gr/noads";
  "network.trr.backup-uri" = "https://dns.quad9.net/dns-query";
  "network.trr.excluded-domains" = "ts.net"; # tailscale magicDNS
  # arkenfox - 0800 **Searchbar/Form/etc**
  "browser.urlbar.speculativeConnect.enabled" = false;
  "browser.urlbar.quicksuggest.enabled" = false;
  "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
  "browser.urlbar.suggest.quicksuggest.sponsored" = false;
  # redundant by policy SearchSuggestEnabled
  # "browser.search.suggest.enabled" = false;
  "browser.urlbar.suggest.searches" = false;
  "browser.urlbar.trending.featureGate" = false;
  "browser.urlbar.addons.featureGate" = false;
  "browser.urlbar.amp.featureGate" = false;
  "browser.urlbar.importantDates.featureGate" = false;
  "browser.urlbar.market.featureGate" = false;
  "browser.urlbar.mdn.featureGate" = false;
  "browser.urlbar.weather.featureGate" = false;
  "browser.urlbar.wikipedia.featureGate" = false;
  "browser.urlbar.yelp.featureGate" = false;
  "browser.urlbar.yelpRealtime.featureGate" = false;
  # redundant by policy DisableFormHistory
  # "browser.formfill.enable" = false;
  "browser.search.separatePrivateDefault" = true;
  "browser.search.separatePrivateDefault.ui.enabled" = true;
  # arkenfox - 0900 **Passwords/Passkeys**
  # partially redundant by policies PasswordManagerEnabled, OfferToSaveLogins
  "signon.autofillForms" = false;
  "signon.formlessCapture.enabled" = false;
  "network.auth.subresource-http-auth-allow" = 1;
  "security.webauthn.always_allow_direct_attestation" = false;
  # arkenfox - 1000 **Disk Avoidance**
  "browser.cache.disk.enable" = false;
  "browser.privatebrowsing.forceMediaMemoryCache" = true;
  "media.memory_cache_max_size" = 65536;
  "browser.sessionstore.privacy_level" = 2;
  "toolkit.winRegisterApplicationRestart" = false;
  "browser.shell.shortcutFavicons" = false;
  # arkenfox - 1200-1700 **HTTPS/Tabs**
  "security.ssl.require_safe_negotiation" = true;
  "security.tls.enable_0rtt_data" = false;
  "security.cert_pinning.enforcement_level" = 2;
  "security.remote_settings.crlite_filters.enabled" = true;
  "security.pki.crlite_mode" = 2;
  # redundant by policy HttpsOnlyMode
  # "dom.security.https_only_mode" = true;
  "dom.security.https_only_mode_send_http_background_request" = false;
  "security.ssl.treat_unsafe_negotiation_as_broken" = true;
  "browser.xul.error_pages.expert_bad_cert" = true;
  "network.http.referer.XOriginTrimmingPolicy" = 2;
  "privacy.userContext.enabled" = true;
  "privacy.userContext.ui.enabled" = true;
  "privacy.userContext.newTabContainerOnLeftClick.enabled" = true;
  # arkenfox - 2000 **Plugins/WebRTC**
  "media.peerconnection.ice.proxy_only_if_behind_proxy" = true;
  "media.peerconnection.ice.default_address_only" = true;
  # arkenfox - 2600-2800 **Misc**
  "dom.disable_window_move_resize" = true;
  "browser.download.start_downloads_in_tmp_dir" = true;
  "browser.helperApps.deleteTempFileOnExit" = true;
  "browser.uitour.enabled" = false;
  "browser.uitour.url" = "";
  "devtools.debugger.remote-enabled" = false;
  "permissions.default.shortcuts" = 2;
  "permissions.manager.defaultsUrl" = "";
  "network.IDN_show_punycode" = true;
  "pdfjs.disabled" = false;
  "pdfjs.enableScripting" = false;
  "browser.tabs.searchclipboardfor.middleclick" = false;
  "browser.contentanalysis.enabled" = false;
  "browser.contentanalysis.default_result" = 0;
  "privacy.antitracking.isolateContentScriptResources" = true;
  "security.csp.reporting.enabled" = false;
  "browser.download.useDownloadDir" = false;
  "browser.download.alwaysOpenPanel" = false;
  "browser.download.manager.addToRecentDocs" = false;
  "browser.download.always_ask_before_handling_new_types" = true;
  "extensions.enabledScopes" = 5;
  "extensions.postDownloadThirdPartyPrompt" = false;
  # arkenfox - 2700 **ETP**
  "browser.contentblocking.category" = "strict";
  "privacy.antitracking.enableWebcompat" = false;
  "privacy.trackingprotection.allow_list.baseline.enabled" = true;
  "privacy.trackingprotection.allow_list.convenience.enabled" = true;
  # arkenfox - 2800 **Cleaning/Sanitization**
  # partially redundant by policy SanitizeOnShutdown,
  # keeping for posterity
  "privacy.sanitize.sanitizeOnShutdown" = true;
  "privacy.clearOnShutdown_v2.cache" = true;
  "privacy.clearOnShutdown_v2.historyFormDataAndDownloads" = true;
  "privacy.clearOnShutdown_v2.browsingHistoryAndDownloads" = true;
  "privacy.clearOnShutdown_v2.downloads" = true;
  "privacy.clearOnShutdown_v2.formdata" = true;
  "privacy.clearOnShutdown_v2.cookiesAndStorage" = true;
  "privacy.clearSiteData.cache" = true;
  "privacy.clearSiteData.cookiesAndStorage" = false;
  "privacy.clearSiteData.historyFormDataAndDownloads" = false;
  "privacy.clearSiteData.browsingHistoryAndDownloads" = true;
  "privacy.clearSiteData.formdata" = true;
  "privacy.clearHistory.cache" = true;
  "privacy.clearHistory.cookiesAndStorage" = true;
  "privacy.clearHistory.historyFormDataAndDownloads" = true;
  "privacy.clearHistory.browsingHistoryAndDownloads" = true;
  "privacy.clearHistory.formdata" = true;
  "privacy.sanitize.timeSpan" = 0;
  # arkenfox - 4500 **extra RFP**
  "privacy.window.maxInnerWidth" = 1600;
  "privacy.window.maxInnerHeight" = 900;
  "privacy.resistFingerprinting.block_mozAddonManager" = true;
  "privacy.spoof_english" = 1;
  "widget.non-native-theme.use-theme-accent" = false;
  "browser.link.open_newwindow" = 3;
  "browser.link.open_newwindow.restriction" = 0;
  # arkenfox 6000-7000 **Don't Touch, Don't Bother**
  "extensions.blocklist.enabled" = true;
  "network.http.referer.spoofSource" = false;
  "security.dialog_enable_delay" = 1000;
  "privacy.firstparty.isolate" = false;
  "extensions.webcompat.enable_shims" = true;
  "security.tls.version.enable-deprecated" = false;
  "extensions.webcompat-reporter.enabled" = false;
  "extensions.quarantinedDomains.enabled" = true;
  "geo.enabled" = false;
  "full-screen-api.enabled" = false;
  "permissions.default.geo" = 2;
  "permissions.default.camera" = 0;
  "permissions.default.microphone" = 0;
  "permissions.default.desktop-notification" = 2;
  "permissions.default.xr" = 2;
  "security.ssl3.ecdhe_ecdsa_aes_128_sha" = false;
  "security.ssl3.ecdhe_ecdsa_aes_256_sha" = false;
  "security.ssl3.ecdhe_rsa_aes_128_sha" = false;
  "security.ssl3.ecdhe_rsa_aes_256_sha" = false;
  # redundant by policies DisabledCiphers and SSLVersionMin
  # "security.ssl3.rsa_aes_128_gcm_sha256" = false;
  # "security.ssl3.rsa_aes_256_gcm_sha384" = false;
  # "security.ssl3.rsa_aes_128_sha" = false;
  # "security.ssl3.rsa_aes_256_sha" = false;
  # "security.tls.version.min" = 3;
  "security.ssl.disable_session_identifiers" = true;
  "network.http.sendRefererHeader" = 2;
  "network.http.referer.trimmingPolicy" = 0;
  "network.http.referer.defaultPolicy" = 2;
  "network.http.referer.defaultPolicy.pbmode" = 2;
  # arkenfox - 8500 **Telemetry** 
  # REDUNDANT: covered by policy DisableTelemetry
  "datareporting.policy.dataSubmissionEnabled" = false;
  "datareporting.healthreport.uploadEnabled" = false;
  "toolkit.telemetry.unified" = false;
  "toolkit.telemetry.enabled" = false;
  "toolkit.telemetry.server" = "data:,";
  "toolkit.telemetry.archive.enabled" = false;
  "toolkit.telemetry.newProfilePing.enabled" = false;
  "toolkit.telemetry.shutdownPingSender.enabled" = false;
  "toolkit.telemetry.updatePing.enabled" = false;
  "toolkit.telemetry.bhrPing.enabled" = false;
  "toolkit.telemetry.firstShutdownPing.enabled" = false;
  "toolkit.telemetry.coverage.opt-out" = true;
  "toolkit.coverage.opt-out" = true;
  "toolkit.coverage.endpoint.base" = "";
  # arkenfox - 9000 **Misc (2)**
  "browser.startup.homepage_override.mstone" = "ignore";
  # redundant by policy UserMessaging
  # "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons" = false;
  # "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features" = false;
  "browser.urlbar.showSearchTerms.enabled" = false;
  "network.predictor.enabled" = false;
  "network.predictor.enable-prefetch" = false;
}