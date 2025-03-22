class Application {

	constructor() {
		this.serviceWorkerRegistration = null;
		this.notificationPermissionGranted = false;
		this.pushSubscription = null;

		this.serverECDSAPublicKey = "-----BEGIN PUBLIC KEY-----\nMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAErs3Ubk2mgyduvALp3KOKstXR5d2E\ng/9vCmYfQbIGGkPnq8SWtxZvDaykqS6dMmaVEuQjqm1WweIkmMfu0I3ACw==\n-----END PUBLIC KEY-----\n";
	}

	async init(){
		await this.registerServiceWorker();
		await this.obtainNotificationPermission();
		await this.getNotificationApiTokens();

		document.getElementById('sub_btn').addEventListener('click', () => {
			this.subscribeToNotifications();
		});
	}

	async registerServiceWorker() {
		if(!('serviceWorker' in navigator)){
			console.log('Service worker not supported');
			return;
		}

		try {
			const registration = await navigator.serviceWorker.register('/sw.js');
			console.log(registration);
			this.serviceWorkerRegistration = registration;
		} catch(e) {
			this.serviceWorkerRegistration = null;
			console.error('Service worker registration failed!');
			console.error(e);
		}
	}

	async obtainNotificationPermission() {
		if(!('Notification' in window)){
			console.log('Notifications not supported');
			return;
		}

		this.notificationPermissionGranted = (Notification.permission === "granted");
		if(this.notificationPermissionGranted){
			console.log('Permission already granted');
			return;
		}

		if(Notification.permission === "denied"){
			console.log('Permission already denied');
			return;
		}

		try {
			const status = await Notification.requestPermission();
			console.log(status);
		} catch(e) {
			console.error('Permission request failed!');
			console.error(e);
		}

		this.notificationPermissionGranted = (Notification.permission === "granted");
	}

	async getNotificationApiTokens() {
		if(!this.serviceWorkerRegistration){
			console.log('Service worker not registered');
			return;
		}

		const pushManager = this.serviceWorkerRegistration.pushManager;
		console.log(pushManager);

		this.pushSubscription = await pushManager.getSubscription();
		document.getElementById('sub_btn').style.display = this.pushSubscription ? "none" : "block";
		console.log("pushSubscription: ", this.pushSubscription);
	}

	async subscribeToNotifications() {
		if(this.pushSubscription){
			console.log('Already subscribed');
			console.log(this.pushSubscription);
			return;
		}

		if(!this.serviceWorkerRegistration){
			console.log('Service worker not registered');
			return;
		}

		const pushManager = this.serviceWorkerRegistration.pushManager;
		const formattedKey = this.serverECDSAPublicKey
			.split("\n")
			.map(line => line.trim())
			.filter((line) => !line.trim().startsWith("----"))
			.join("")
			.replace(/\+/g, "-")
			.replace(/\//g, "_")
			.replace(/=*$/, "")
			.trim();
		console.log("formattedKey: ", formattedKey);
		this.pushSubscription = await pushManager.subscribe({
			userVisibleOnly: true,
			applicationServerKey: formattedKey
		});

		document.getElementById('sub_btn').style.display = this.pushSubscription ? "none" : "block";
		console.log("pushSubscription: ", this.pushSubscription);
	}

}

const main = async () => {
	const app = new Application();
	await app.init();
};

window.addEventListener('load', main);