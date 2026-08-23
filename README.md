# Getting My Pink Back

**Live: https://drwitteck.github.io/pink-back/**

A private iPhone tracker for a weekly injectable medication. Logs weight, side effects, and
how you actually feel, and charts the three together so the pattern is visible.

No account, no server, no analytics. There is no backend to send anything to — your entries
live in your phone's browser storage and never leave the device.

## Install it

Open the link above in Safari on your iPhone, then **Share → Add to Home Screen**, and from
then on launch it from that icon.

That step is not cosmetic. iOS erases `localStorage` for ordinary Safari tabs after **7 days**
without a visit; web apps launched from the Home Screen are exempt. The app nags you with a
banner until you do it, and Settings → Storage tells you which mode you're in.

Deleting the icon deletes the data with it, so take a backup now and then.

## What it tracks

- **Date** — one entry per day, backdate anything you missed
- **Weight** — lb or kg, charted over 30D / 90D / all time
- **Side effects** — pick from a built-in list or add your own, each mild / moderate / severe
- **How you feel** — a 1–5 scale, charted against weight so you can see how they move together
- Optional per entry: injection day + dose (2.5 → 15 mg), and freeform notes

Four tabs: **Today** (log + summary), **Trends** (charts and stats), **History** (everything
by month), **Settings** (accent, units, backup, erase).

Settings offers six accent colours — Rose, Berry, Plum, Coral, Moss, Ocean — which restyle
the whole app instantly and persist with your data. Every pair is checked against WCAG AA in
both light and dark, and a test enforces that, so a new theme can't quietly ship unreadable.
Note that this cannot change the **Home Screen icon**: iOS captures that once, at the moment
you Add to Home Screen, and exposes no way for a web app to change it afterwards.

## Backup

Settings offers **Export CSV** (for a spreadsheet or your doctor) and **Export backup (JSON)**,
which round-trips losslessly through **Restore from backup**. Both go through the iOS share
sheet, so you can drop them into Files, iCloud, or Mail.

Since the data exists in exactly one place, this is the only thing standing between you and a
lost phone. Worth doing every few weeks.

## Working on it

```sh
cd web
./serve.sh          # serves on your LAN; prints the URL to open on the phone
node test.js        # 33 logic tests against a stub DOM, no browser needed
```

`index.html` is the entire app — markup, styles, and logic in one file, no dependencies and
no build step. The file you edit is the file that ships.

Note that `localhost` is a secure context, so the service worker registers during local
development too and can serve you a stale page while you're editing. Hard-reload, or use
Safari's Develop → Disable Caches.

## Deploying

Push to `main`. That's the whole process.

The workflow runs `node web/test.js` first and only publishes if it passes, so a broken build
can't reach your phone. Cache invalidation is automatic: the workflow stamps `CACHE` in
`sw.js` with the commit SHA at publish time, so every deploy retires the previous cache. You
never edit that line, and the build fails loudly if the stamp stops applying.

Expect a change to land on the **second** launch of the app. The first renders from the cache
it already has while the new service worker downloads in the background; the next picks it up.
That's normal service worker behaviour, not a stuck deploy.

## Why GitHub Pages and not your own Mac

`serve.sh` is genuinely local, but plain `http://` is not a secure context, so the service
worker can't register — your Mac would have to be awake and on the same Wi-Fi every time you
opened the app.

Over HTTPS the worker caches the whole app on first visit, so it opens instantly and offline
with no Mac involved. The *page* is public; the *data* still never leaves your phone, because
there is no server to send it to. Anyone who finds the URL sees an empty tracker.

## Files

```
web/
  index.html            the entire app
  manifest.webmanifest  makes Add to Home Screen give a real icon and no Safari chrome
  sw.js                 offline cache; CACHE is rewritten by CI, don't edit it
  test.js               headless tests against a stub DOM
  serve.sh              local server + prints the LAN URL
  icon.swift            regenerates the icons: `swift web/icon.swift web`
  icon-*.png
.github/workflows/pages.yml
```
