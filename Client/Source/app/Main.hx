package app;

import app.ClientApp;

class Main {
	static var _started = false;

	public static function main() {
		if (_started)
			return;
		_started = true;
		var app = new ClientApp();
		app.start();
	}
}
