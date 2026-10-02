const CACHE_NAME = "megjet-app-v22";
const GUARD_URL = "./workflow-guard.js?v=8";
const APP_SHELL = [
  "./assets/menu-options.js?v=1",
  "./",
  "./index.html",
  "./manifest.webmanifest",
  "./assets/operations.js?v=2",
  "./assets/menu-photo-preview.js?v=1",
  "./assets/operations.css?v=3",
  GUARD_URL,
  "./interface-preferences.js?v=10",
  "./assets/traffic-support.js?v=3",
  "./assets/menu-language.js?v=1",
  "./assets/install-app.js?v=1",
  "./icons/megjet-photo-192.png",
  "./icons/megjet-photo-512.png",
  "./icons/megjet-photo-maskable-512.png"
];

self.addEventListener("install", event => {
  event.waitUntil(caches.open(CACHE_NAME).then(cache => cache.addAll(APP_SHELL)));
  self.skipWaiting();
});

self.addEventListener("activate", event => {
  event.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(key => key !== CACHE_NAME).map(key => caches.delete(key))))
      .then(() => self.clients.claim())
  );
});

async function withWorkflowGuard(response) {
  if (!response) return response;
  const type = response.headers.get("content-type") || "";
  if (!type.includes("text/html")) return response;

  let html = await response.text();
  html = html.replace(/<script src="\.\/workflow-guard\.js(?:\?[^"]*)?"><\/script>/g, "");
  html = html.replace("</body>", '<script src="./workflow-guard.js?v=8"></script></body>');

  const headers = new Headers(response.headers);
  headers.delete("content-length");
  headers.delete("content-encoding");
  return new Response(html, {
    status: response.status,
    statusText: response.statusText,
    headers
  });
}

self.addEventListener("fetch", event => {
  if (event.request.method !== "GET") return;
  const url = new URL(event.request.url);
  if (url.origin !== self.location.origin) return;

  if (event.request.mode === "navigate") {
    event.respondWith((async () => {
      try {
        const response = await fetch(event.request);
        if (response.ok) {
          const copy = response.clone();
          caches.open(CACHE_NAME).then(cache => cache.put("./index.html", copy));
        }
        return withWorkflowGuard(response);
      } catch {
        return withWorkflowGuard(await caches.match("./index.html"));
      }
    })());
    return;
  }

  if (url.pathname.endsWith("/workflow-guard.js")) {
    event.respondWith(
      fetch(event.request, { cache: "no-store" })
        .then(response => {
          if (response.ok) {
            const copy = response.clone();
            caches.open(CACHE_NAME).then(cache => cache.put(event.request, copy));
          }
          return response;
        })
        .catch(() => caches.match(event.request))
    );
    return;
  }

  event.respondWith(
    caches.match(event.request).then(cached => {
      const network = fetch(event.request).then(response => {
        if (response.ok) {
          const copy = response.clone();
          caches.open(CACHE_NAME).then(cache => cache.put(event.request, copy));
        }
        return response;
      }).catch(() => cached);
      return cached || network;
    })
  );
});

self.addEventListener('push',event=>{
 let data={title:'Megjet',body:'Open Megjet to view updates.',tag:'megjet-update',url:'./'};
 try{data={...data,...event.data.json()};}catch{}
 event.waitUntil(self.registration.showNotification(data.title,{body:data.body,icon:'./icons/megjet-photo-192.png',badge:'./icons/megjet-photo-192.png',tag:data.tag,data:{url:data.url},renotify:true}));
});
self.addEventListener('notificationclick',event=>{
 event.notification.close();
 const target=new URL('./',self.registration.scope).href;
 event.waitUntil(self.clients.matchAll({type:'window',includeUncontrolled:true}).then(async clients=>{
  const existing=clients.find(client=>client.url.startsWith(self.registration.scope));
  if(existing){await existing.focus();return existing.navigate(target);}return self.clients.openWindow(target);
 }));
});
