package app.services;

import sidewinder.client.AutoClient;
import app.services.IAuthService;
import core.util.BuildConfig;

/**
 * Central place to create & hold generated AutoClient service proxies.
 * Uses a singleton for simplicity; can be refactored to DI later.
 */
class ServiceRegistry {
	#if (js || html5)
	// For html5: determine default base at runtime (inline const not possible for dynamic values)
	public static var instance(default, null):ServiceRegistry = new ServiceRegistry(determineDefaultBase());

	static function determineDefaultBase():String {
		var defined = BuildConfig.apiHost(); // compile-time literal ("" if not set)
		if (defined != null && defined != "")
			return defined;
		return js.Browser.window.location.origin + "/api"; // adjust '/api' if not needed
	}
	#else
	public static var instance(default, null):ServiceRegistry = new ServiceRegistry("http://localhost:8000");
	#end

	public var auth(default, null):IAuthService;

	public var baseUrl(default, null):String;

	public function new(baseUrl:String) {
		// Ensure trailing slash not required; callers pass base without slash
		if (StringTools.endsWith(baseUrl, "/"))
			baseUrl = baseUrl.substr(0, baseUrl.length - 1);
		this.baseUrl = baseUrl;
		auth = AutoClient.create(IAuthService, baseUrl);
	}
}
