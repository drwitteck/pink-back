# Zep Tracker

A private, offline iPhone tracker for Zepbound. No account, no server, no analytics —
your data never leaves the phone.

Two builds, same features:

| | `ZepTracker/` (native) | `web/` (web app) |
|---|---|---|
| Install | Xcode → your iPhone | Safari → Add to Home Screen |
| Needs | Xcode + Apple ID | a URL to open |
| Rebuild cadence | every 7 days (free Apple ID) | never |
| Storage | SwiftData, durable | `localStorage`, durable **only** from the Home Screen icon |

Start with the web version — it's instant. See `web/README.md` for the storage caveat,
which matters more than anything else there.

## What it tracks

- **Date** — one entry per day, backdate anything you missed
- **Weight** — lb or kg, charted over 30D / 90D / all time
- **Side effects** — pick from the usual tirzepatide list (or add your own), each with mild / moderate / severe
- **How you feel** — 1–5 scale, charted alongside weight so you can see the pattern
- Optional per-entry: injection day + dose (2.5 → 15 mg), freeform notes

Three tabs: **Today** (log + at-a-glance summary), **Trends** (charts + stats), **History** (everything, grouped by month).
Settings has a CSV export — worth doing occasionally, since on-device-only means no automatic backup.

## Getting it on your phone

The iOS platform component isn't installed in Xcode yet. One time only:

```sh
xcodebuild -downloadPlatform iOS      # ~8 GB, takes a while
```

Then:

```sh
xcodegen generate                     # only needed if you add/remove files
open ZepTracker.xcodeproj
```

In Xcode:

1. Plug in your iPhone (or pair it over Wi-Fi via Window → Devices and Simulators).
2. Select the **ZepTracker** target → **Signing & Capabilities** → set **Team** to your Apple ID.
   Add the account under Xcode → Settings → Accounts if it isn't there.
   If the bundle ID `com.derekwitteck.ZepTracker` is taken, change it to anything unique.
3. Pick your iPhone in the device dropdown and hit ⌘R.
4. First run only: on the phone, Settings → General → VPN & Device Management → trust your developer certificate.

**Free Apple ID:** the app stops launching after 7 days; rebuild from Xcode to reset it.
Your data survives — it's a reinstall over the top, not a delete. A $99/yr Apple Developer
account extends that to a year.

## Project layout

```
project.yml                  xcodegen spec — the .xcodeproj is generated from this
ZepTracker/
  ZepTrackerApp.swift        entry point + tab bar
  Models/LogEntry.swift      the SwiftData model, feeling scale, dose ladder
  Models/SideEffect.swift    side effect struct + catalog of common ones
  Views/HomeView.swift       Today tab
  Views/EntryEditorView.swift  add/edit sheet + side effect picker
  Views/TrendsView.swift     charts and stats
  Views/HistoryView.swift    full log by month
  Views/SettingsView.swift   units, CSV export
  Support/Units.swift        lb/kg conversion and formatting
  Support/CSVExport.swift    export
```

Weight is stored canonically in kilograms and converted for display, so flipping units
in Settings never rewrites your data.
