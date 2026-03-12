package app.state;

import app.cms.ICmsManager;
import app.models.CmsModels;
import app.cms.PageRenderer;
import app.state.AppState;
import haxe.ds.StringMap;
import haxe.Timer;

/**
 * PageNavigator manages page navigation, deep linking, and navigation events.
 */
class PageNavigator {
	/**
	 * Example: Component can call this to prevent navigation if needed.
	 * Usage: PageNavigator.instance.addBeforeNavigateHook(() -> {
	 *   if (hasUnsavedChanges) {
	 *     components.Notifications.show("Please save your changes before leaving this page.", "warning");
	 *     return false;
	 *   }
	 *   return true;
	 * });
	 */
	public static var instance:PageNavigator;

	public var currentPage:String;
	public var currentAnchor:String;
	/**
	 * The current query parameters, parsed from the URL hash (e.g., #products?product_id=123)
	 */
	public var currentQueryParams:Map<String, String> = new Map();
	public var onBeforeNavigate:Array<Void->Bool> = [];
	public var onNavigate:Array<GetPageResponse->Void> = [];
	public var appState:AppState;
	public var cmsManager:ICmsManager;
	public var renderer:PageRenderer;

	public function new(appState:AppState, cmsManager:ICmsManager, renderer:PageRenderer) {
		this.appState = appState;
		this.cmsManager = cmsManager;
		this.renderer = renderer;
		instance = this;

		#if html5
		js.Browser.window.onhashchange = function(_) {
			var hash = js.Browser.window.location.hash;
			if (hash != null && hash.length > 1) {
				var hashContent = hash.substr(1);
				var queryIndex = hashContent.indexOf("?");
				var queryString = "";
				var mainPart = hashContent;
				if (queryIndex != -1) {
					mainPart = hashContent.substr(0, queryIndex);
					queryString = hashContent.substr(queryIndex + 1);
				}
				var parts = mainPart.split(":");
				var pageId = parts[0];
				var anchor = parts.length > 1 ? parts[1] : null;
				var params = parseQueryString(queryString);
				// Avoid re-navigating if we're already on this page/anchor/params
				if (pageId != instance.currentPage || anchor != instance.currentAnchor || !mapEquals(params, instance.currentQueryParams)) {
					navigate(pageId, anchor, params);
				}
			}
		};
		#end
	}

	/**
	 * Request navigation to a page and optional anchor.
	 * Returns true if navigation succeeded, false if blocked.
	 */
	/**
	 * Request navigation to a page, optional anchor, and optional query parameters.
	 * Returns true if navigation succeeded, false if blocked.
	 */
	public function navigate(pageId:String, ?anchor:String, ?queryParams:Map<String, String>):Bool {
		// Fire beforeNavigate hooks, allow blocking
		for (hook in onBeforeNavigate) {
			if (!hook())
				return false;
		}
		currentPage = pageId;
		currentAnchor = anchor;
		currentQueryParams = queryParams != null ? queryParams : new Map();
		appState.currentPage = pageId;
		appState.currentAnchor = anchor;
		// Determine if the pageId is numeric or a slug path
		// Note: use charAt check instead of Std.parseInt because on JS target,
		// Std.parseInt returns NaN (not null) for non-numeric strings
		var firstChar = pageId.charAt(0);
		var isNumeric = (firstChar >= "0" && firstChar <= "9");
		if (isNumeric) {
			// Numeric page ID — fetch by ID
			var numericId = Std.parseInt(pageId);
			cmsManager.getPage(numericId != null ? numericId : 0, function(response:GetPageResponse) {
				if (response.success && response.page != null) {
					for (hook in onNavigate) {
						hook(response);
					}
				}
			});
		} else {
			// Slug-based path (e.g. "/company/about") — strip leading slash and fetch by slug
			var slug = pageId;
			if (slug.charAt(0) == "/")
				slug = slug.substr(1);
			cmsManager.getPageBySlug(slug, true, function(response:GetPageResponse) {
				if (response.success && response.page != null) {
					for (hook in onNavigate) {
						hook(response);
					}
				}
			});
		}
		// Update deep link (URL)
		updateUrl(pageId, anchor, currentQueryParams);
		return true;
	}

	/**
	 * Register a hook to block navigation (return false to block).
	 */
	public function addBeforeNavigateHook(hook:Void->Bool) {
		onBeforeNavigate.push(hook);
	}

	/**
	 * Register a hook to run after navigation.
	 */
	public function addNavigateHook(hook:GetPageResponse->Void) {
		onNavigate.push(hook);
	}

	/**
	 * Update browser URL for deep linking.
	 */
	/**
	 * Update browser URL for deep linking, including query parameters.
	 */
	public function updateUrl(pageId:String, ?anchor:String, ?queryParams:Map<String, String>) {
		var url = '#' + pageId;
		if (anchor != null && anchor != "")
			url += ':' + anchor;
		if (queryParams != null && queryParams.iterator().hasNext()) {
			var first = true;
			for (k in queryParams.keys()) {
				url += first ? '?' : '&';
				url += encodeURIComponent(k) + '=' + encodeURIComponent(queryParams.get(k));
				first = false;
			}
		}
		#if html5
		js.Browser.window.location.hash = url;
		#end
	}

	/**
	 * Parse deep link from URL and navigate on app load.
	 * Returns true if handled, false if no deep link present.
	 */
	/**
	 * Parse deep link from URL and navigate on app load, including query parameters.
	 * Returns true if handled, false if no deep link present.
	 */
	public function handleInitialDeepLink():Bool {
		#if html5
		var hash = js.Browser.window.location.hash;
		if (hash != null && hash.length > 1) {
			var hashContent = hash.substr(1);
			var queryIndex = hashContent.indexOf("?");
			var queryString = "";
			var mainPart = hashContent;
			if (queryIndex != -1) {
				mainPart = hashContent.substr(0, queryIndex);
				queryString = hashContent.substr(queryIndex + 1);
			}
			var parts = mainPart.split(":");
			var pageId = parts[0];
			var anchor = parts.length > 1 ? parts[1] : null;
			var params = parseQueryString(queryString);
			navigate(pageId, anchor, params);
			return true;
		}
		#end
		return false;
	}

	/**
	 * Parse a query string (e.g., "product_id=123&foo=bar") into a Map<String, String>.
	 */
	function parseQueryString(query:String):Map<String, String> {
		var map = new Map<String, String>();
		if (query != null && query != "") {
			var pairs = query.split('&');
			for (pair in pairs) {
				var eq = pair.indexOf('=');
				if (eq > 0) {
					var key = decodeURIComponent(pair.substr(0, eq));
					var value = decodeURIComponent(pair.substr(eq + 1));
					map.set(key, value);
				} else if (pair != "") {
					map.set(decodeURIComponent(pair), "");
				}
			}
		}
		return map;
	}

	/**
	 * Compare two maps for equality (shallow, string keys/values).
	 */
	function mapEquals(a:Map<String, String>, b:Map<String, String>):Bool {
		if (a == null && b == null) return true;
		if (a == null || b == null) return false;
		var countA = 0;
		for (k in a.keys()) {
			countA++;
			if (!b.exists(k) || a.get(k) != b.get(k)) return false;
		}
		var countB = 0;
		for (k in b.keys()) countB++;
		return countA == countB;
	}
	function encodeURIComponent(s:String):String {
		#if html5
		return untyped __js__("encodeURIComponent")(s);
		#else
		return StringTools.urlEncode(s);
		#end
	}

	function decodeURIComponent(s:String):String {
		#if html5
		return untyped __js__("decodeURIComponent")(s);
		#else
		return StringTools.urlDecode(s);
		#end
	}
}
