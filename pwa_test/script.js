class Application {

	constructor() {
		this.subscriber_id = null;
		this.installPromptEvent = null;
		this.serviceWorkerRegistration = null;
		this.notificationPermissionGranted = false;
		this.pushSubscription = null;

		this.serverVapidPublicKey = "BJ_7EexZJthghP8XA62XKkuOqtoh6wnMwNjukIbAARok1DhiXVD5HiXw0XUu4D_QCIy9jfH_FUmTJPHFOPhBfIQ";
	}

	log(...messages) {
		console.log(...messages);

		const logElement = document.getElementById('logs');
		for(let message of messages){
			if(!message){ continue; }
			if(typeof message !== "string"){ continue; }
			logElement.innerHTML += `<div>${message}</div>`;	
		}
	}

	async init(){
		const urlParams = new URLSearchParams(window.location.search);
		const dataParam = urlParams.get('data');
		if(dataParam){
			this.log(`Data parameter: ${dataParam}`);
		}

		this.subscriber_id = Cookies.get("sid");
		await this.registerServiceWorker();
		await this.obtainNotificationPermission();
		await this.getNotificationApiTokens();

		window.addEventListener("beforeinstallprompt", (e) => {
			e.preventDefault();
			this.installPromptEvent = e;
			document.getElementById('install_btn').style.display = "block";
		});

		document.getElementById('install_btn').addEventListener('click', () => {
			this.requestAppInstallation();
		});
		document.getElementById('notif_btn').addEventListener('click', () => {
			this.obtainNotificationPermission();
		});
		document.getElementById('sub_btn').addEventListener('click', () => {
			this.subscribeToNotifications();
		});
		document.getElementById('schedule_btn').addEventListener('click', () => {
			this.setNotificationOptions();
		});
	}

	async registerServiceWorker() {
		if(!('serviceWorker' in navigator)){
			this.log('Service worker not supported');
			return;
		}

		try {
			const registration = await navigator.serviceWorker.register('/sw.js');
			console.log("Service Worker registration: ", registration);
			this.serviceWorkerRegistration = registration;
		} catch(e) {
			this.serviceWorkerRegistration = null;
			this.log('Service worker registration failed!');
			this.log(e);
		}
	}

	async requestAppInstallation() {
		if(!this.installPromptEvent){
			this.log('App installation prompt not available');
			return;
		}

		const promptEvent = this.installPromptEvent;
		this.installPromptEvent = null;

		promptEvent.prompt();
		promptEvent.userChoice.then((choiceResult) => {
			if(choiceResult.outcome === 'accepted'){
				this.log('User accepted the app installation prompt');
			} else {
				this.log('User dismissed the app installation prompt');
			}
		});
	}

	async obtainNotificationPermission() {
		document.getElementById('notif_btn').style.display = "none";
		if(!('Notification' in window)){
			this.log('Notifications not supported');
			return;
		}

		this.notificationPermissionGranted = (Notification.permission === "granted");
		if(this.notificationPermissionGranted){
			this.log('Notification permission already granted');
			return;
		}

		if(Notification.permission === "denied"){
			this.log('Notification permission already denied');
			return;
		}

		try {
			const status = await Notification.requestPermission();
			this.log(`Notification permission status ${status}`);
		} catch(e) {
			this.log('Notification permission request failed!');
			this.log(e);
			document.getElementById('notif_btn').style.display = "block";
		}

		this.notificationPermissionGranted = (Notification.permission === "granted");
		if(Notification.permission !== "granted" && Notification.permission !== "denied"){
			this.log('Notification permission not granted or denied');
			document.getElementById('notif_btn').style.display = "block";
			return;
		}
	}

	async getNotificationApiTokens() {
		if(!this.serviceWorkerRegistration){
			this.log('Service Worker not registered');
			return;
		}

		const pushManager = this.serviceWorkerRegistration.pushManager;
		if(!pushManager){
			this.log('Push Manager does not exist');
			return;
		}
		this.log(pushManager);

		this.pushSubscription = await pushManager.getSubscription();
		await this.registerPushSubscription();
	}

	async subscribeToNotifications() {
		if(this.pushSubscription){
			this.log('Already subscribed', this.pushSubscription);
			return;
		}

		if(!this.serviceWorkerRegistration){
			this.log('Service Worker not registered');
			return;
		}

		const pushManager = this.serviceWorkerRegistration.pushManager;
		if(!pushManager){
			this.log('Push Manager does not exist');
			return;
		}
		
		this.pushSubscription = await pushManager.subscribe({
			userVisibleOnly: true,
			applicationServerKey: this.serverVapidPublicKey
		});

		await this.registerPushSubscription();
	}

	async registerPushSubscription(options){
		document.getElementById('sub_btn').style.display = this.pushSubscription ? "none" : "block";
		console.log("pushSubscription: ", this.pushSubscription);
		if(!this.pushSubscription){
			this.log('No push subscription to register');
			return;
		}

		const response = await axios({
			method: "post",
			url: "/api/web_push/register",
			headers: {
				"Content-Type": "application/json"
			},
			data: {
				subscriber_id: this.subscriber_id,
				subscription: this.pushSubscription,
				notification_permission_granted: this.notificationPermissionGranted,
				notification_options: options
			}
		});
		const responseData = response.data;
		this.log(responseData);
		if(!responseData.success){
			this.log('Failed to register push subscription');
			return;
		}
		this.subscriber_id = responseData.result?.subscriber_id;
		if(!this.subscriber_id){
			this.log('Failed to get subscriber id');
			return;
		}
		this.log(`Subscriber id: ${this.subscriber_id}`);
		Cookies.set("sid", this.subscriber_id);

		const notificationOptions = responseData.result?.notification_options;
		if(!notificationOptions){
			this.log(`No notification options found for subscriber`);
			return;
		}
		document.getElementById("notification_disabled").checked = notificationOptions.disabled || false;
		document.getElementById("notification_interval").value = Math.round((notificationOptions.interval || 10 * 60 * 1000) / (1000 * 60)); 
		document.getElementById("notification_repeat").checked = notificationOptions.repeat || false;
	}

	async setNotificationOptions(){
		const options = {
			disabled: document.getElementById("notification_disabled").checked || false,
			interval: (parseInt(document.getElementById("notification_interval").value) || 10) * 60 * 1000,
			repeat: document.getElementById("notification_repeat").checked || false
		};
		console.log("Setting notification options: ", options);
		await this.registerPushSubscription(options);
	}

}

const main = async () => {
	const app = new Application();
	await app.init();
};

window.addEventListener('load', main);