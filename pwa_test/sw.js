self.addEventListener('install', (e) => {
	console.log('Service worker installed');
  self.skipWaiting();
});

self.addEventListener("push", (e) => {
	const notificationData = JSON.parse(e.data.text());
	const notificationOptions = {
		body: notificationData.body,
		data: notificationData.data,
		icon: notificationData.icon,
		badge: notificationData.badge,
		image: notificationData.image
	};
	self.registration.showNotification(notificationData.title, notificationOptions)
});

self.addEventListener("notificationclick", (e) => {
	e.notification.close();
	const url = e.notification.data.url;

	e.waitUntil(clients.matchAll({
			type: "window",
		}).then((clientList) => {
			for(const client of clientList){
				if(client.url === url && "focus" in client){ return client.focus(); }
			}
			if(clients.openWindow){ return clients.openWindow(url); }
		})
  );
});