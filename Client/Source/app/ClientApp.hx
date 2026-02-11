package app;

import core.ClientBootstrap;
import haxe.ui.core.Component;
import app.views.MainView;
import sidewinder.DI;
import hx.injection.ServiceCollection;
import app.cms.ICmsManager;
import app.cms.CmsManager;

class ClientApp extends ClientBootstrap {
	override public function configureServices(services:ServiceCollection):Void {
		// Register application-specific services
		services.addService(hx.injection.ServiceType.Singleton, ICmsManager, CmsManager);
	}

	override public function createMainView():Component {
		return new MainView();
	}
}
