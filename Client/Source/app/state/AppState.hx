package app.state;

import app.services.ServiceRegistry;
import app.services.AsyncServiceRegistry;
import app.models.AuthModels;
import app.models.AuthModels.UserPublic;
import core.state.Observable;

/** Global application state & selections */
class AppState {
	public static var instance(default, null):AppState = new AppState();

	public var services:ServiceRegistry;
	public var asyncServices:AsyncServiceRegistry; // global async service access

	// Authentication state
	public var currentUser:Observable<Null<UserPublic>> = new Observable<Null<UserPublic>>(null);
	public var authToken:Observable<Null<String>> = new Observable<Null<String>>(null);
	public var isAuthenticated(get, never):Bool;

	// Navigation state
	public var currentPage:String = "";
	public var currentAnchor:String = null;

	private function new() {
		services = ServiceRegistry.instance;
		asyncServices = AsyncServiceRegistry.instance;
	}

	function get_isAuthenticated():Bool {
		return currentUser.value != null && authToken.value != null;
	}

	public function setAuthentication(user:UserPublic, token:String):Void {
		currentUser.value = user;
		authToken.value = token;

		// Inject into CookieJar for API requests
		if (asyncServices != null && asyncServices.cookieJar != null) {
			var cookieStr = "session_token=" + token + "; Path=/; Max-Age=604800";
			asyncServices.cookieJar.setCookie(cookieStr, asyncServices.baseUrl);
		}

		// Store token in local storage for persistence
		#if js
		try {
			js.Browser.window.localStorage.setItem("authToken", token);
		} catch (e:Dynamic) {
			trace("Failed to save auth token to localStorage: " + e);
		}
		#end
	}

	public function clearAuthentication():Void {
		currentUser.value = null;
		authToken.value = null;

		if (asyncServices != null && asyncServices.cookieJar != null) {
			asyncServices.cookieJar.clear();
		}

		#if js
		try {
			js.Browser.window.localStorage.removeItem("authToken");
		} catch (e:Dynamic) {
			trace("Failed to remove auth token from localStorage: " + e);
		}
		#end
	}

	public function loadStoredToken():Null<String> {
		if (authToken.value != null) {
			return authToken.value;
		}
		#if js
		try {
			return js.Browser.window.localStorage.getItem("authToken");
		} catch (e:Dynamic) {
			trace("Failed to load auth token from localStorage: " + e);
			return null;
		}
		#else
		return null;
		#end
	}
}
