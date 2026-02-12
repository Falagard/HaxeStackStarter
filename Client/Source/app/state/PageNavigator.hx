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
		// Fetch page info asynchronously and trigger rendering
		cmsManager.getPage(Std.parseInt(pageId), function(response:GetPageResponse) {
			if (response.success && response.page != null) {
				// Renderer is handled by MainView observing PageNavigator events,
				// or we should consolidate it here. But removing it prevents double-render
				// if MainView is also doing it.
				// renderer.renderPage(response.page, anchor);

				// Fire onNavigate hooks
				for (hook in onNavigate) {
					hook();
				}
			}
		});
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
