{
  DisableAppUpdate = true;
  AppAutoUpdate = false;
  DisableSystemAddonUpdate = true;
  ExtensionUpdate = true;

  DisableTelemetry = true;
  DisableFirefoxStudies = true;
  DisableFeedbackCommands = true;
  DisableRemoteImprovements = true;

  DisableFirefoxAccounts = true;

  AIControls = {
    Default = { Value = "blocked"; Locked = true; };
    Translations = { Value = "blocked"; Locked = true; };
    PDFAltText = { Value = "blocked"; Locked = true; };
    SmartTabGroups = { Value = "blocked"; Locked = true; };
    LinkPreviewKeyPoints = { Value = "blocked"; Locked = true; };
    SidebarChatbot = { Value = "blocked"; Locked = true; };
    SmartWindow = { Value = "blocked"; Locked = true; };
  };
  GenerativeAI = {
    ChatEnabled = false;
  };

  NetworkPrediction = false;
  CaptivePortal = false;
  DisableEncryptedClientHello = false;

  HttpsOnlyMode = "force_enabled";
  SSLVersionMin = "tls1.2";
  PostQuantumKeyAgreementEnabled = true;
  DisabledCiphers = {
    TLS_RSA_WITH_AES_128_CBC_SHA = true;
    TLS_RSA_WITH_AES_256_CBC_SHA = true;
    TLS_RSA_WITH_AES_128_CBC_SHA256 = true;
    TLS_RSA_WITH_AES_256_CBC_SHA256 = true;
    TLS_RSA_WITH_AES_128_GCM_SHA256 = true;
    TLS_RSA_WITH_AES_256_GCM_SHA384 = true;
    TLS_RSA_WITH_3DES_EDE_CBC_SHA = true;
  };

  EnableTrackingProtection = {
    Value = true;
    Cryptomining = true;
    Fingerprinting = true;
    Locked = true;
  };

  DNSOverHTTPS = {
    Enabled = true;
    ProviderURL = "https://doh.libredns.gr/noads";
    Locked = true;
    Fallback = false;
    ExcludedDomains = [
      "ts.net" # tailscale MagicDNS
    ];
  };

  PasswordManagerEnabled = false;
  OfferToSaveLogins = false;
  DisableMasterPasswordCreation = true;

  DisableFormHistory = true;
  SearchSuggestEnabled = false;

  DisableSecurityBypass = {
    InvalidCertificate = true;
    SafeBrowsing = false;
  };

  PopupBlocking = {
    Default = true;
    Locked = true;
  };

  SanitizeOnShutdown = {
    Cache = true;
    Cookies = true;
    Downloads = false;
    FormData = true;
    History = true;
    Sessions = false;
    SiteSettings = false;
    OfflineApps = true;
    Locked = false;
  };

  DontCheckDefaultBrowser = true;
  NoDefaultBookmarks = true;
  OverrideFirstRunPage = "";
  OverridePostUpdatePage = "";
  DisableProfileRefresh = true;
  UserMessaging = {
    WhatsNew = false;
    ExtensionRecommendations = false;
    FeatureRecommendations = false;
    UrlbarInterventions = false;
    SkipOnboarding = true;
    MoreFromMozilla = false;
    Locked = false;
  };
  FirefoxHome = {
    Search = true;
    TopSites = false;
    SponsoredTopSites = false;
    Highlights = false;
    Pocket = false;
    SponsoredPocket = false;
    Snippets = false;
    Locked = false;
  };
}
