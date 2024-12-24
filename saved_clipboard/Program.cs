using System.Diagnostics;
using LedCSharp;
using System.Runtime.InteropServices;


public class Program {

	private static IntPtr _keyboardHookID = IntPtr.Zero;

	private delegate IntPtr LowLevelKeyboardProc(int nCode, IntPtr wParam, IntPtr lParam);

	[DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
	private static extern IntPtr SetWindowsHookEx(int idHook, LowLevelKeyboardProc lpfn, IntPtr hMod, uint dwThreadId);

	[DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
	[return: MarshalAs(UnmanagedType.Bool)]
	private static extern bool UnhookWindowsHookEx(IntPtr hhk);

	[DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
	private static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);

	[DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
	private static extern IntPtr GetModuleHandle(string lpModuleName);

	static async void DrawHeart() {
		LogitechGSDK.LogiLedSetLighting(0, 0, 0);

		keyboardNames[][] keysToLight = {
			new keyboardNames[]{ keyboardNames.SIX },
			new keyboardNames[]{ keyboardNames.F7, keyboardNames.F6, keyboardNames.F4, keyboardNames.F3 },
			new keyboardNames[]{ keyboardNames.THREE, keyboardNames.NINE },
			new keyboardNames[]{ keyboardNames.E, keyboardNames.I },
			new keyboardNames[]{ keyboardNames.F, keyboardNames.J },
			new keyboardNames[]{ keyboardNames.N, keyboardNames.V },
			new keyboardNames[]{ keyboardNames.SPACE }
		};
		foreach(keyboardNames[] currKeysToLight in keysToLight){
			foreach(keyboardNames currKey in currKeysToLight){
				LogitechGSDK.LogiLedSetLightingForKeyWithKeyName(currKey, 100, 0, 0);
			}
			await Task.Delay(500);
		}

		await Task.Delay(500);
		LogitechGSDK.LogiLedSetLighting(0, 0, 0);
		await Task.Delay(500);
		foreach(keyboardNames[] currKeysToLight in keysToLight){
			foreach(keyboardNames currKey in currKeysToLight){
				LogitechGSDK.LogiLedSetLightingForKeyWithKeyName(currKey, 100, 0, 0);
			}
		}

		await Task.Delay(500);
		LogitechGSDK.LogiLedSetLighting(0, 0, 0);
		await Task.Delay(500);

		DrawHeart();
	}

	private const int NUM_STORAGE_SLOTS = 5;
	private const int STORAGE_START_KEY = 129;
    private const int NUM_LOCK_KEY = 20;
    private const int CAPS_LOCK_KEY = 144;
    private const int SCROLL_LOCK_KEY = 145;
	private const int WM_KEYDOWN = 0x0100;
	private const int WM_KEYUP = 0x0101;
    private static IDataObject?[] clipboardStorage = new IDataObject?[NUM_STORAGE_SLOTS];
	private static int currClipboardStorage = 0;
	private static keyboardNames[] gKeyNames = {keyboardNames.G_1, keyboardNames.G_2, keyboardNames.G_3, keyboardNames.G_4, keyboardNames.G_5};

	private static IDataObject? ReadClipboard() {
		IDataObject result = new DataObject();
		IDataObject? dataObject = Clipboard.GetDataObject();
		if(dataObject == null){ return null; }

		string[] formats = dataObject.GetFormats() ?? Array.Empty<string>();
		bool hasData = false;
		foreach (string format in formats) {
			try {
				object? data = dataObject.GetData(format);
				if (data != null) {
					result.SetData(format, data);
					hasData = true;
				}
			} catch (ExternalException ex) { 
				Debug.WriteLine($"Error {ex.ErrorCode}: {ex.Message}");
			}
		}
		if(!hasData){ return null; }
		return result;
	}

	private static IntPtr SetKeyboardHook() {
		using (Process curProcess = Process.GetCurrentProcess())
		using (ProcessModule? curModule = curProcess.MainModule) {
			if(curModule == null){ throw new Exception("currModule is null"); }
			return SetWindowsHookEx(13, KeyboardHookCallback, GetModuleHandle(curModule.ModuleName), 0);
		}
	}

	private static void HandleGKeyDown(int storageIndex){
		if(Control.ModifierKeys.HasFlag(Keys.Control)){
			Console.WriteLine("Ctrl is pressed for storage " + storageIndex);
			clipboardStorage[storageIndex] = null;
			if(storageIndex == currClipboardStorage){
				Console.WriteLine("Clearing current clipboard");
				Clipboard.Clear();
			}
			RecolorGKeys();
			return;
		}
		if(storageIndex == currClipboardStorage){
			return;
		}

		IDataObject? currClipboardData = ReadClipboard();
		clipboardStorage[currClipboardStorage] = currClipboardData;

		currClipboardStorage = storageIndex;
		IDataObject? savedClipboardData = clipboardStorage[currClipboardStorage];
		if(savedClipboardData == null){
			Console.WriteLine("Switched to Null Storage " + currClipboardStorage);
			Clipboard.Clear();
		} else {
			Console.WriteLine("Switched to Valid Storage " + currClipboardStorage);
			Clipboard.SetDataObject(savedClipboardData, true);
		}
		RecolorGKeys();
	}

  private static IntPtr KeyboardHookCallback(int nCode, IntPtr wParam, IntPtr lParam) {
		if (nCode >= 0 && wParam == (IntPtr)WM_KEYDOWN) {
			int vkCode = Marshal.ReadInt32(lParam);
			if(vkCode >= STORAGE_START_KEY && vkCode < STORAGE_START_KEY + NUM_STORAGE_SLOTS){
				int storageIndex = vkCode - STORAGE_START_KEY;
				HandleGKeyDown(storageIndex);
			}
		} else if(nCode >= 0 && wParam == (IntPtr)WM_KEYUP) {
            int vkCode = Marshal.ReadInt32(lParam);
            if (vkCode == NUM_LOCK_KEY || vkCode == CAPS_LOCK_KEY || vkCode == SCROLL_LOCK_KEY) {
				Console.WriteLine("lock key pressed");
                Task.Delay(50).ContinueWith(t => RecolorGKeys());
            }
        }
		return CallNextHookEx(_keyboardHookID, nCode, wParam, lParam);
	}

	private static void SetConsoleExitHook() {
		Task.Run(() => {
			Console.WriteLine("Press \"ENTER\" to continue...");
			Console.ReadLine();

			Console.WriteLine("Exiting App");
			Application.Exit();
		});
	}

	private static void StartLogitechSDK(){
		bool LedInitialized = LogitechGSDK.LogiLedInitWithName("Set G-Key Status");

		if (!LedInitialized) {
			Console.WriteLine("LogitechGSDK.LogiLedInit() failed.");
			return;
		}

		Console.WriteLine("Logitech LED SDK Initialized");

		LogitechGSDK.LogiLedSetTargetDevice(LogitechGSDK.LOGI_DEVICETYPE_PERKEY_RGB);
		RecolorGKeys();
	}

	private static void RecolorGKeys(){
		LogitechGSDK.LogiLedSetLighting(160, 0, 200);
		for(int i=0; i<NUM_STORAGE_SLOTS; i++){
			if(i == currClipboardStorage){
				LogitechGSDK.LogiLedSetLightingForKeyWithKeyName(gKeyNames[i], 0, 200, 0);
			} else if(clipboardStorage[i] != null){
				LogitechGSDK.LogiLedSetLightingForKeyWithKeyName(gKeyNames[i], 200, 200, 0);
			} else {
				LogitechGSDK.LogiLedSetLightingForKeyWithKeyName(gKeyNames[i], 200, 200, 200);
			}
		}
		if (!Control.IsKeyLocked(Keys.NumLock)) {
			LogitechGSDK.LogiLedSetLightingForKeyWithKeyName(keyboardNames.NUM_LOCK, 255, 0, 0);
        }
        if (Control.IsKeyLocked(Keys.CapsLock)) {
            LogitechGSDK.LogiLedSetLightingForKeyWithKeyName(keyboardNames.CAPS_LOCK, 0, 255, 0);
        }
		if (Control.IsKeyLocked(Keys.Scroll)) {
			LogitechGSDK.LogiLedSetLightingForKeyWithKeyName(keyboardNames.SCROLL_LOCK, 0, 255, 0);
		}
    }

	[STAThread]
	public static void Main(string[] args) {
		StartLogitechSDK();
		_keyboardHookID = SetKeyboardHook();

		SetConsoleExitHook();
		Application.Run();

		Console.WriteLine("Shutting Down");
		UnhookWindowsHookEx(_keyboardHookID);
		LogitechGSDK.LogiLedShutdown();

		Console.WriteLine("Shutdown Complete");
	}

}
