# Zep Tracker — web version

**Live: https://drwitteck.github.io/zep-tracker/**

Same tracker as the native app, as a single self-contained page. No build step, no
dependencies, no network calls. Data lives in this phone's `localStorage`.

## Install it on your phone

Open the link above in Safari, then **Share → Add to Home Screen**. Always launch it from
that icon afterwards — see the storage note below, it is the whole ballgame.

## Deploying a change

Push to `main`. That's the whole process. The workflow runs `node web/test.js` and only
publishes if it passes, so a broken build can't reach your phone.

Cache invalidation is automatic: the workflow stamps `CACHE` in `sw.js` with the commit SHA
at publish time, so every deploy retires the previous cache. You never edit that line, and
the build fails loudly if the stamp doesn't apply.

Expect the change to land on the **second** launch of the app. The first launch renders from
the cache it already has while the new service worker downloads in the background; the next
one picks it up. That's normal service worker behaviour, not a stuck deploy.

## Working on it locally

```sh
./serve.sh          # then open the printed http://<mac-ip>:8080 on your iPhone
node test.js        # 33 logic tests, no browser needed
```

## Read this part — it decides whether your data survives

iOS erases `localStorage` for ordinary Safari tabs after **7 days** without a visit.
Web apps launched from the **Home Screen** are exempt.

So: open the page in Safari, tap **Share → Add to Home Screen**, and from then on open it
from that icon. The app shows a banner until you do, and Settings → Storage tells you which
mode you're in. Deleting the icon deletes the data with it — take a backup occasionally.

## Why it's on GitHub Pages and not your Mac

`./serve.sh` is genuinely local, but plain `http://` is not a secure context, so the service
worker can't register — your Mac would have to be awake and on the same Wi-Fi every single
time you opened the app.

Over HTTPS the service worker caches the whole app on first visit, so it opens instantly and
offline with no Mac involved. The *page* at https://drwitteck.github.io/zep-tracker/ is public; your
*data* still never leaves the phone, because there is no server to send it to. Anyone who
finds the URL sees an empty tracker.

## Files

```
index.html            the entire app — markup, styles, logic
manifest.webmanifest  makes Add to Home Screen give a real icon and no Safari chrome
sw.js                 offline cache (HTTPS/localhost only). Bump CACHE when index.html changes
test.js               headless tests against a stub DOM
serve.sh              local server + prints the LAN URL
icon-*.png
```

## Moving data between the two apps

Both export the same CSV columns, so you can diff or merge them by hand. **Export backup
(JSON)** → **Restore from backup** is the lossless path, but it only round-trips between web
installs — the native app uses SwiftData, not this JSON shape.
