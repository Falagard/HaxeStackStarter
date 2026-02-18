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
	public var onBeforeNavigate:Array<Void->Bool> = [];
	public var onNavigate:Array<Void->Void> = [];
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
				var parts = hash.substr(1).split(':');
				var pageId = parts[0];
				var anchor = parts.length > 1 ? parts[1] : null;
				// Avoid re-navigating if we're already on this page/anchor
				if (pageId != instance.currentPage || anchor != instance.currentAnchor) {
					navigate(pageId, anchor);
				}
			}
		};
		#end
	}

	/**
	 * Request navigation to a page and optional anchor.
	 * Returns true if navigation succeeded, false if blocked.
	 */
	public function navigate(pageId:String, ?anchor:String):Bool {
		// Fire beforeNavigate hooks, allow blocking
		for (hook in onBeforeNavigate) {
			if (!hook())
				return false;
		}
		currentPage = pageId;
		currentAnchor = anchor;
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
						hook();
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
						hook();
					}
				}
			});
		}
		// Update deep link (URL)
		updateUrl(pageId, anchor);
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
	public function addNavigateHook(hook:Void->Void) {
		onNavigate.push(hook);
	}

	/**
	 * Update browser URL for deep linking.
	 */
	public function updateUrl(pageId:String, ?anchor:String) {
		var url = '#' + pageId;
		if (anchor != null && anchor != "")
			url += ':' + anchor;
		#if html5
		js.Browser.window.location.hash = url;
		#end
	}

	/**
	 * Parse deep link from URL and navigate on app load.
	 * Returns true if handled, false if no deep link present.
	 */
	public function handleInitialDeepLink():Bool {
		#if html5
		var hash = js.Browser.window.location.hash;
		if (hash != null && hash.length > 1) {
			var parts = hash.substr(1).split(':');
			var pageId = parts[0];
			var anchor = parts.length > 1 ? parts[1] : null;
			navigate(pageId, anchor);
			return true;
		}
		#end
		return false;
	}
}
