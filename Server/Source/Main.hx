package;

import app.ServerApp;
import app.services.DatabaseSeeder;
import sidewinder.core.DI;

class Main extends ServerApp {
	public function new() {
		super();
	}
	
	public static function main() {
		var args = Sys.args();
		trace("Main.main() args: " + args);
		
		var isSeed = false;
		for (arg in args) {
			if (arg == "--seed") {
				isSeed = true;
				break;
			}
		}

		if (isSeed) {
			trace("Main.main() SEED MODE DETECTED!");
			var app = new Main();
			app.minimalInitForSeeding();
			trace("Main.main() Starting DatabaseSeeder.runSeed()...");
			DatabaseSeeder.runSeed();
			trace("Main.main() SEEDING COMPLETED. Exiting.");
			Sys.exit(0);
		}
		
		trace("Main.main() Normal boot mode");
		var app = new Main();
		app.exec();
	}
}
