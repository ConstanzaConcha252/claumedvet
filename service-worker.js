// Service worker de ClauMedVet — permite que la app cargue sin internet
// una vez que se abrió al menos una vez con conexión.
const CACHE_NAME = 'claumedvet-shell-v1';
const APP_SHELL = [
  './ClauMedVet.html',
  './manifest.json',
  './icon-192.png',
  './icon-512.png'
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(APP_SHELL)).catch(() => {})
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k)))
    )
  );
  self.clients.claim();
});

// Estrategia: intenta la red primero (así siempre ves la versión más nueva
// cuando hay internet); si falla por falta de conexión, usa la última copia
// guardada. Las llamadas a Supabase (u otros dominios externos) no se tocan:
// siguen su propio manejo de errores dentro de la app.
self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);
  if (url.origin !== self.location.origin) return;
  if (event.request.method !== 'GET') return;

  event.respondWith(
    fetch(event.request)
      .then((response) => {
        const copy = response.clone();
        caches.open(CACHE_NAME).then((cache) => cache.put(event.request, copy));
        return response;
      })
      .catch(() => caches.match(event.request).then((cached) => cached || caches.match('./ClauMedVet.html')))
  );
});
