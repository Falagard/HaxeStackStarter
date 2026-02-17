package app;

import core.ServerBootstrap;
import core.middleware.AuthenticationMiddleware;
import core.middleware.LoggingMiddleware;
import core.middleware.BotDetectionMiddleware;
import hx.injection.ServiceCollection;
import hx.injection.ServiceType;
import sidewinder.AutoRouter;
import sidewinder.DI;
import sidewinder.Router;
import snake.http.HTTPStatus;
import haxe.Json;
import app.services.IAuthService;
import app.services.AuthService;
import app.services.ICmsService;
import app.services.CmsService;
import app.services.IMegaMenuService;
import app.services.MegaMenuService;
import app.models.AuthModels.LoginRequest;
import app.util.PageLoader;
import app.util.PageSerializer;
import app.util.VersionRestorer;
import app.services.DatabaseSeeder;

class ServerApp extends ServerBootstrap {
	override public function configureServices(services:ServiceCollection):Void {
		services.addService(ServiceType.Scoped, IAuthService, AuthService);
		services.addService(ServiceType.Scoped, ICmsService, CmsService);
		services.addService(ServiceType.Scoped, IMegaMenuService, MegaMenuService);
		services.addService(ServiceType.Scoped, PageLoader, PageLoader);
		services.addService(ServiceType.Scoped, PageSerializer, PageSerializer);
		services.addService(ServiceType.Scoped, VersionRestorer, VersionRestorer);
		services.addService(ServiceType.Scoped, DatabaseSeeder, DatabaseSeeder);
	}

	override public function init():Void {
		super.init();
		var seeder = DI.get(DatabaseSeeder);
		seeder.seed();
	}

	override public function configureMiddleware():Void {
		// Log requests
		LoggingMiddleware.use();

		// Authenticate API requests
		AuthenticationMiddleware.use(cache);

		// Redirect bots to SEO pages
		BotDetectionMiddleware.use();
	}

	override public function configureRoutes(router:Router):Void {
		// Custom login endpoint to set HttpOnly cookie
		router.add("POST", "/api/auth/login", (req, res) -> {
			try {
				var loginRequest:LoginRequest = req.jsonBody;
				if (loginRequest == null || loginRequest.emailOrUsername == null || loginRequest.password == null) {
					res.sendResponse(HTTPStatus.BAD_REQUEST);
					res.setHeader("Content-Type", "application/json");
					res.endHeaders();
					res.write(Json.stringify({error: "Missing email/username or password"}));
					res.end();
					return;
				}

				var authService:AuthService = cast DI.get(IAuthService);
				var result = authService.login(loginRequest);

				if (result.success) {
					cache.set("session:" + result.token, result.user, 604800);

					res.sendResponse(HTTPStatus.OK);
					res.setHeader("Content-Type", "application/json");
					res.setCookie("session_token", result.token, {
						path: "/",
						domain: null,
						maxAge: "604800",
						httpOnly: true,
						secure: false
					});
					res.endHeaders();
					res.write(Json.stringify(result));
					res.end();
				} else {
					res.sendResponse(HTTPStatus.UNAUTHORIZED);
					res.setHeader("Content-Type", "application/json");
					res.endHeaders();
					res.write(Json.stringify({success: false, error: result.error}));
					res.end();
				}
			} catch (e:Dynamic) {
				res.sendResponse(HTTPStatus.INTERNAL_SERVER_ERROR);
				res.setHeader("Content-Type", "application/json");
				res.endHeaders();
				res.write(Json.stringify({error: "Internal server error"}));
				res.end();
			}
		});

		// Custom logout endpoint to clear cookie
		router.add("POST", "/api/auth/logout", (req, res) -> {
			try {
				var sessionToken:String = null;
				if (req.cookies != null && req.cookies.exists("session_token")) {
					sessionToken = req.cookies.get("session_token");
				}

				if (sessionToken != null) {
					var authService:AuthService = cast DI.get(IAuthService);
					authService.invalidateSession(sessionToken);
					cache.set("session:" + sessionToken, null, 0);
				}
				res.sendResponse(HTTPStatus.OK);
				res.setHeader("Content-Type", "application/json");
				res.setCookie("session_token", "", {
					path: "/",
					domain: null,
					maxAge: "0",
					httpOnly: true,
					secure: false
				});
				res.endHeaders();
				res.write(Json.stringify({success: true}));
				res.end();
			} catch (e:Dynamic) {
				res.sendResponse(HTTPStatus.INTERNAL_SERVER_ERROR);
				res.setHeader("Content-Type", "application/json");
				res.endHeaders();
				res.write(Json.stringify({error: "Internal server error"}));
				res.end();
			}
		});

		// Custom current user endpoint using request context
		router.add("GET", "/api/auth/me", (req, res) -> {
			try {
				// Prevent caching of auth status
				res.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
				res.setHeader("Pragma", "no-cache");
				res.setHeader("Expires", "0");

				// User is populated by AuthenticationMiddleware (serialized in params)
				var userJson = req.params.get("auth_user_json");

				res.sendResponse(HTTPStatus.OK);
				res.setHeader("Content-Type", "application/json");
				res.endHeaders();

				if (userJson != null) {
					res.write(userJson);
				} else {
					// Return null/empty for no user
					res.write("null");
				}
				res.end();
			} catch (e:Dynamic) {
				res.sendResponse(HTTPStatus.INTERNAL_SERVER_ERROR);
				res.setHeader("Content-Type", "application/json");
				res.endHeaders();
				res.write(Json.stringify({error: "Internal server error"}));
				res.end();
			}
		});
		// Build AutoRouter mappings
		AutoRouter.build(router, IAuthService, () -> DI.get(IAuthService), cache);
		AutoRouter.build(router, ICmsService, () -> DI.get(ICmsService), cache);
		AutoRouter.build(router, IMegaMenuService, () -> DI.get(IMegaMenuService), cache);

		// SEO HTML for bots
		router.add("GET", "/seo/:slug", (req, res) -> {
			var slug = req.params.get("slug");
			var cms:ICmsService = cast DI.get(ICmsService);
			var pageResp = cms.getPageBySlug(slug, true);
			if (!pageResp.success || pageResp.page == null) {
				res.sendResponse(HTTPStatus.NOT_FOUND);
				res.endHeaders();
				res.write("Page not found");
				res.end();
				return;
			}
			var page = pageResp.page;

			// Serve SEO HTML for bots (or debugging)
			var html = '<!DOCTYPE html>';
			html += '<html lang="en">';
			html += '<head>';
			html += '<meta charset="UTF-8">';
			html += '<meta name="viewport" content="width=device-width, initial-scale=1.0">';
			html += '<title>' + page.title + '</title>';
			html += '<meta name="description" content="' + page.title + '" />';
			html += '<meta name="robots" content="index, follow" />';
			html += '</head>';
			html += '<body>';
			html += page.seoHtml;
			html += '</body></html>';
			res.sendResponse(HTTPStatus.OK);
			res.setHeader("Content-Type", "text/html; charset=UTF-8");
			res.endHeaders();
			res.write(html);
			res.end();
		});
	}
}
