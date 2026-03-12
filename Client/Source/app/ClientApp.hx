package app;

import core.ClientBootstrap;
import haxe.ui.core.Component;
import app.views.MainView;
import sidewinder.core.DI;
import hx.injection.ServiceCollection;
import app.cms.ICmsManager;
import app.cms.CmsManager;
import haxe.ui.Toolkit;
import app.state.AppState;
import app.services.AsyncServiceRegistry;
import app.models.AuthModels;

class ClientApp extends ClientBootstrap {
	override public function configureServices(services:ServiceCollection):Void {
		// Register application-specific services
		services.addService(hx.injection.ServiceType.Singleton, ICmsManager, CmsManager);
	}

	override public function createMainView():Component {
		return new MainView();
	}

	override public function start():Void {
		initDI();
		Toolkit.init();

		var appState = AppState.instance;
		var token = appState.loadStoredToken();

		if (token != null) {
			// Manually prime the cookie jar so the request works
			var asyncServices = AsyncServiceRegistry.instance;
			if (asyncServices.cookieJar != null) {
				var cookieStr = "session_token=" + token + "; Path=/; Max-Age=604800";
				asyncServices.cookieJar.setCookie(cookieStr, asyncServices.baseUrl);
			}

			asyncServices.auth.getCurrentUserAsync(function(user:Null<UserPublic>) {
				if (user != null) {
					appState.setAuthentication(user, token);
				} else {
					appState.clearAuthentication();
				}
				showMain();
			}, function(error:Dynamic) {
				trace("Failed to restore session: " + error);
				appState.clearAuthentication();
				showMain();
			});
		} else {
			showMain();
		}
	}

	private function showMain():Void {
		var main = createMainView();
		if (main != null) {
			Toolkit.screen.addComponent(main);
		}
	}
}
