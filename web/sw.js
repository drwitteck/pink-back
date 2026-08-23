// Caches the whole app shell so it opens with no network at all.
//
// The deploy workflow rewrites the line below to the commit SHA on every publish, which is
// what invalidates the old cache. Don't bump it by hand - CI owns it. Locally it stays
// 'pinkback-dev', so during development use a hard reload (or Safari's Disable Caches) after
// editing index.html.
const CACHE = 'pinkback-dev';
const SHELL = ['./', 'index.html', 'manifest.webmanifest', 'icon-180.png', 'icon-192.png', 'icon-512.png'];

self.addEventListener('install', event => {
  event.waitUntil(caches.open(CACHE).then(c => c.addAll(SHELL)).then(() => self.skipWaiting()));
});

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', event => {
  if (event.request.method !== 'GET') return;
  event.respondWith(
    caches.match(event.request, { ignoreSearch: true }).then(hit => {
      if (hit) return hit;
      return fetch(event.request).catch(() => caches.match('index.html'));
    })
  );
});
