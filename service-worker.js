// Service worker de ClauMedVet — permite que la app cargue sin internet
// una vez que se abrió al menos una vez con conexión.
const CACHE_NAME = 'claumedvet-shell-v2';
const APP_SHELL = [
  './ClauMedVet.html',
  './manifest.json',
  './icon-192.png',
  './icon-512.png'
];
// Librería de login (Supabase Auth). Debe ser EXACTAMENTE la misma URL que
// carga ClauMedVet.html. Es la única URL externa que se guarda: las llamadas
// a la API de Supabase (datos clínicos) nunca pasan por esta caché.
const SUPABASE_JS_URL = 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.117.3/dist/umd/supabase.js';

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => Promise.all([
      cache.addAll(APP_SHELL).catch(() => {}),
      cache.add(new Request(SUPABASE_JS_URL, { mode: 'cors' })).catch(() => {})
    ])).catch(() => {})
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

self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);
  if (event.request.method !== 'GET') return;

  // La librería de login tiene versión fija, así que nunca cambia: se usa la
  // copia guardada y solo se descarga si todavía no está.
  if (event.request.url === SUPABASE_JS_URL) {
    event.respondWith(
      caches.match(SUPABASE_JS_URL).then((cached) => cached || fetch(event.request).then((response) => {
        if (response.ok) {
          const copy = response.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(SUPABASE_JS_URL, copy));
        }
        return response;
      }))
    );
    return;
  }

  // Cualquier otro dominio externo (Supabase, fuentes, etc.) no se toca.
  if (url.origin !== self.location.origin) return;

  // Archivos propios: intenta la red primero (así siempre ves la versión más
  // nueva cuando hay internet); si falla por falta de conexión, usa la última
  // copia guardada.
  event.respondWith(
    fetch(event.request)
      .then((response) => {
        if (response.ok) {
          const copy = response.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(event.request, copy));
        }
        return response;
      })
      .catch(() => caches.match(event.request).then((cached) => cached || caches.match('./ClauMedVet.html')))
  );
});
