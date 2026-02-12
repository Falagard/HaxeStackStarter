package core;

import sidewinder.SideWinderServer;
import sidewinder.SideWinderRequestHandler;
import hx.injection.ServiceCollection;
import sidewinder.DI;
import sidewinder.HybridLogger;
import sidewinder.InMemoryCacheService;
import sidewinder.ICacheService;
// import sidewinder.Database;
import sidewinder.IDatabaseService;
import sidewinder.SqliteDatabaseService;
import lime.app.Application;
import lime.ui.WindowAttributes;
import lime.ui.Window;
import sys.net.Host;
import sidewinder.Router;
import snake.http.BaseHTTPRequestHandler;
import hx.injection.ServiceType;

class ServerBootstrap extends Application {
	public var config:ServerConfig;
	public var httpServer:SideWinderServer;
	public var router:Router;
	public var cache:ICacheService;

	public function new() {
		super();
		config = new ServerConfig();
		// Allow subclasses to modify config before init
		configure();
		init();
	}

	public function configure():Void {
		// Override in subclass
	}

	public function init():Void {
		// Initialize database
		// Database.runMigrations(); - Moved to DI
		HybridLogger.init();

		// Configure SideWinderRequestHandler
		BaseHTTPRequestHandler.protocolVersion = config.protocol;
		SideWinderRequestHandler.corsEnabled = config.corsEnabled;
		SideWinderRequestHandler.cacheEnabled = config.cacheEnabled;
		SideWinderRequestHandler.silent = config.silent;

		router = SideWinderRequestHandler.router;

		// DI Initialization
		DI.init(c -> {
			c.addService(ServiceType.Singleton, ICacheService, InMemoryCacheService);
			c.addService(ServiceType.Singleton, IDatabaseService, SqliteDatabaseService);
			configureServices(c);
		});

		cache = DI.get(ICacheService);

		// Run migrations
		var db = DI.get(IDatabaseService);
		db.runMigrations();

		// Configure generic middleware/routes
		configureMiddleware();
		configureRoutes(router);

		// Start server
		httpServer = new SideWinderServer(new Host(config.host), config.port, SideWinderRequestHandler, true, config.directory);
	}

	public function configureServices(services:ServiceCollection):Void {
		// Override in subclass to register app services
	}

	public function configureMiddleware():Void {
		// Override to add middleware usage
	}

	public function configureRoutes(router:Router):Void {
		// Override to add custom routes
	}

	public override function update(deltaTime:Int):Void {
		httpServer.handleRequest();
	}

	override public function createWindow(attributes:WindowAttributes):Window {
		return null;
	}
}
