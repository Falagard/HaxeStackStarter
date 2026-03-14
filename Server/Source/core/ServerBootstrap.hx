package core;

import sidewinder.interfaces.IWebServer;
import sidewinder.core.WebServerFactory;
import sidewinder.routing.SideWinderRequestHandler;
import hx.injection.ServiceCollection;
import sidewinder.core.DI;
import sidewinder.logging.HybridLogger;
import sidewinder.interfaces.InMemoryCacheService;
import sidewinder.interfaces.ICacheService;
// import sidewinder.Database;
import sidewinder.interfaces.IDatabaseService;
import sidewinder.services.SqliteDatabaseService;
import lime.app.Application;
import lime.ui.WindowAttributes;
import lime.ui.Window;
import sys.net.Host;
import sidewinder.routing.Router;
import snake.http.BaseHTTPRequestHandler;
import hx.injection.ServiceType;
import sidewinder.interfaces.IslandManager;

class ServerBootstrap extends Application {
	public var config:ServerConfig;
	public var httpServer:IWebServer;
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
		// Run migrations
		var db = DI.get(IDatabaseService);
		db.runMigrations();

		afterMigrations();

		// Configure generic middleware/routes
		configureMiddleware();
		configureRoutes(router);

		// Start server
		var serverTypeStr = Sys.getEnv("SIDEWINDER_SERVER");
		var serverType = sidewinder.core.WebServerFactory.WebServerType.HxWell;
		if (serverTypeStr == "civetweb") {
			serverType = sidewinder.core.WebServerFactory.WebServerType.CivetWeb;
		} else if (serverTypeStr == "snake") {
			serverType = sidewinder.core.WebServerFactory.WebServerType.SnakeServer;
		}

		var numIslandsStr = Sys.getEnv("SIDEWINDER_ISLANDS");
		var numIslands = numIslandsStr != null ? Std.parseInt(numIslandsStr) : 4;
		if (numIslands == null || numIslands < 1) numIslands = 4;

		var islandManager = new IslandManager(numIslands);
		httpServer = WebServerFactory.create(serverType, config.host, config.port, SideWinderRequestHandler, config.directory, islandManager);
		httpServer.start();
	}

	public function configureServices(services:ServiceCollection):Void {
		// Override in subclass to register app services
	}

	public function afterMigrations():Void {
		// Override in subclass to run seeding, etc.
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
