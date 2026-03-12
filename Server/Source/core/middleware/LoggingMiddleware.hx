package core.middleware;

import sidewinder.core.App;
import sidewinder.logging.HybridLogger;

class LoggingMiddleware {
	public static function use() {
		App.use((req, res, next) -> {
			HybridLogger.info('${req.method} ${req.path} ' + Sys.time());
			next();
		});
	}
}
