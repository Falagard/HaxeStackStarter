package core;

import haxe.ui.Toolkit;
import haxe.ui.core.Component;
import sidewinder.core.DI;
import hx.injection.ServiceCollection;

class ClientBootstrap {
	public function new() {
		// Constructor
	}

	public function start():Void {
		initDI();
		Toolkit.init();
		var main = createMainView();
		if (main != null) {
			Toolkit.screen.addComponent(main);
		}
	}

	public function initDI():Void {
		DI.init(configureServices);
	}

	public function configureServices(services:ServiceCollection):Void {
		// Override in subclass
	}

	public function createMainView():Component {
		return null; // Override
	}
}
