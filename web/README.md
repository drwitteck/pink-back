# Zep Tracker — web version

Same tracker as the native app, as a single self-contained page. No build step, no
dependencies, no network calls. Data lives in this phone's `localStorage`.

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

## Two ways to host it, and the trade-off

**From your Mac (`./serve.sh`)** — genuinely local, nothing leaves your network. But plain
`http://` is not a secure context, so the service worker can't register: your Mac has to be
awake and on the same Wi-Fi every single time you open the app.

**From any HTTPS static host** (GitHub Pages, Netlify, Cloudflare Pages — all free) — the
service worker caches the whole app on first visit, so it opens instantly, offline, forever,
with no Mac involved. The *page* is public; your *data* still never leaves the phone, because
there is no server to send it to. For daily use this is the one that actually works.

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
