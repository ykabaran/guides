class Application {

	constructor() {
		this.subscriber_id = null;
		this.serviceWorkerRegistration = null;
		this.notificationPermissionGranted = false;
		this.pushSubscription = null;

		this.serverVapidPublicKey = "BJ_7EexZJthghP8XA62XKkuOqtoh6wnMwNjukIbAARok1DhiXVD5HiXw0XUu4D_QCIy9jfH_FUmTJPHFOPhBfIQ";
	}

	async init(){
		this.subscriber_id = Cookies.get("sid");
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
		await this.registerPushSubscription();
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
		this.pushSubscription = await pushManager.subscribe({
			userVisibleOnly: true,
			applicationServerKey: this.serverVapidPublicKey
		});

		await this.registerPushSubscription();
	}

	async registerPushSubscription(){
		document.getElementById('sub_btn').style.display = this.pushSubscription ? "none" : "block";
		console.log("pushSubscription: ", this.pushSubscription);
		if(!this.pushSubscription){ return; }
		console.log(JSON.stringify(this.pushSubscription, null, '\t'));

		const response = await axios({
			method: "post",
			url: "/api/web_push/register",
			headers: {
				"Content-Type": "application/json"
			},
			data: {
				subscriber_id: this.subscriber_id,
				subscription: this.pushSubscription
			}
		});
		const responseData = response.data;
		console.log(responseData);
		if(!responseData.success){
			console.error('Failed to register push subscription');
			return;
		}
		this.subscriber_id = responseData.result?.subscriber_id;
		if(!this.subscriber_id){
			console.error('Failed to get subscriber id');
			return;
		}
		console.log('Subscriber id: ', this.subscriber_id);
		Cookies.set("sid", this.subscriber_id);
	}

}

const main = async () => {
	const app = new Application();
	await app.init();
};

window.addEventListener('load', main);