// userchrome.css usercontent.css activate
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

// fill svg color
user_pref("svg.context-properties.content.enabled", true);

// enable :has selector
user_pref("layout.css.has-selector.enabled", true);

// integrated calculator at urlbar
user_pref("browser.urlbar.suggest.calculator", true);

// integrated unit convertor at urlbar
user_pref("browser.urlbar.unitConversion.enabled", true);

// trim url
user_pref("browser.urlbar.trimHttps", true);
user_pref("browser.urlbar.trimURLs", true);

// show profile management in hamburger menu
user_pref("browser.profiles.enabled", true);

// gtk rounded corners
user_pref("widget.gtk.rounded-bottom-corners.enabled", true);

// show compact mode
user_pref("browser.compactmode.show", true);

// fix sidebar tab drag on linux
user_pref("widget.gtk.ignore-bogus-leave-notify", 1);

user_pref("browser.tabs.allow_transparent_browser", false);

// uidensity -> compact
user_pref("browser.uidensity", 1);

// macos transparent
user_pref("widget.macos.titlebar-blend-mode.behind-window", false);

// don't warn on about:config open
user_pref("browser.aboutConfig.showWarning", false);

user_pref("sidebar.revamp", false);
user_pref("sidebar.verticalTabs", false);

user_pref("uc.tweak.borderless", true);
user_pref("uc.tweak.borderless.no-round", true);
user_pref("uc.tweak.no-custom-icons", true);
user_pref("uc.tweak.no-window-controls", true);
user_pref("uc.tweak.sidebar.wide", true);
user_pref("uc.tweak.sidebar.header", false);
user_pref("uc.tweak.translucency", false);
user_pref("uc.tweak.no-blur", true);
user_pref("uc.tweak.urlbar.not-floating", false);

user_pref("cookiebanners.service.mode", 2);
user_pref("cookiebanners.service.mode.privateBrowsing", 2);
user_pref("browser.quitShortcut.disabled", true);
user_pref("browser.fullscreen.exit_on_escape", false);
user_pref("extensions.pocket.enabled", false);
user_pref("accessibility.force_disabled", 1);
user_pref("media.ffmpeg.vaapi.enabled", true);


// darkman: theme preferences - follow system theme
user_pref("layout.css.prefers-color-scheme.content-override", 2);
user_pref("browser.theme.content-theme", 2);
user_pref("browser.theme.toolbar-theme", 2);


// sideberry: theme preferences - follow system theme
user_pref("svg.context-properties.content.enabled", true);


// ---------------------------------------------------------------------------
// Privacy hardening
// ---------------------------------------------------------------------------

// Disable geolocation API entirely
user_pref("geo.enabled", false);

// Fingerprinting protection (granular alternative to resistFingerprinting)
// +AllTargets enables all protections, -CSSPrefersColorScheme allows system
// dark/light theme to flow through (needed for SurfingKeys, darkman, etc.)
user_pref("privacy.resistFingerprinting", false);
user_pref("privacy.fingerprintingProtection", true);
user_pref("privacy.fingerprintingProtection.pbmode", true);
user_pref("privacy.fingerprintingProtection.overrides", "+AllTargets,-CSSPrefersColorScheme");

// Disable WebGL (prevents GPU fingerprinting -- may break some sites)
user_pref("webgl.disabled", true);

// Disable beacon analytics (sendBeacon tracking on page unload)
user_pref("beacon.enabled", false);

// Disable battery status API (can be used for fingerprinting)
user_pref("dom.battery.enabled", false);

// Disable WebRTC IP leak (prevents exposing local/VPN IP via WebRTC)
user_pref("media.peerconnection.ice.default_address_only", true);
user_pref("media.peerconnection.ice.no_host", true);

// Disable speculative connections (preloading/prefetching to third parties)
user_pref("network.http.speculative-parallel-limit", 0);
user_pref("network.dns.disablePrefetch", true);
user_pref("network.prefetch-next", false);

// Disable telemetry
user_pref("toolkit.telemetry.enabled", false);
user_pref("toolkit.telemetry.unified", false);
user_pref("toolkit.telemetry.archive.enabled", false);

// Disable studies and experiments
user_pref("app.shield.optoutstudies.enabled", false);
user_pref("app.normandy.enabled", false);
