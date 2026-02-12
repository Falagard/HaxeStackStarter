package core.middleware;

import sidewinder.App;
import sidewinder.DI;
import sidewinder.ICacheService;
import app.services.IAuthService;
import snake.http.HTTPStatus;
import haxe.Json;

class AuthenticationMiddleware {
	public static function use(cache:ICacheService) {
		App.use((req, res, next) -> {
			// Skip auth for auth endpoints
			if (req.path.indexOf("/api/auth/") == 0) {
				next();
				return;
			}

			// Require authentication for all other /api/ routes
			if (req.path.indexOf("/api/") == 0) {
				var sessionToken:String = null;
				var authHeader = req.headers.get("Authorization");

				// Debug logging
				trace("[AuthMiddleware] Checking auth for: " + req.path);
				trace("[AuthMiddleware] Authorization Header: " + authHeader);
				if (req.cookies != null) {
					trace("[AuthMiddleware] Cookies: " + req.cookies);
				} else {
					trace("[AuthMiddleware] No cookies found");
				}

				if (authHeader != null && authHeader.indexOf("Bearer ") == 0) {
					sessionToken = authHeader.substring(7);
				}

				if (sessionToken == null && req.cookies != null && req.cookies.exists("session_token")) {
					sessionToken = req.cookies.get("session_token");
				}

				if (sessionToken == null) {
					res.sendResponse(HTTPStatus.UNAUTHORIZED);
					res.setHeader("Content-Type", "application/json");
					res.endHeaders();
					res.write(haxe.Json.stringify({error: "Unauthorized - No session token"}));
					res.end();
					return;
				}

				var cachedUser = cache.get("session:" + sessionToken);
				var user = null;

				if (cachedUser != null) {
					user = cachedUser;
				} else {
					var authService:app.services.AuthService = cast DI.get(IAuthService);
					user = authService.validateSessionToken(sessionToken);

					if (user != null) {
						cache.set("session:" + sessionToken, haxe.Json.stringify({
							id: user.id,
							email: user.email,
							username: user.username,
							emailVerified: user.emailVerified
						}), 604800);
					}
				}

				if (user == null) {
					res.sendResponse(HTTPStatus.UNAUTHORIZED);
					res.setHeader("Content-Type", "application/json");
					res.endHeaders();
					res.write(haxe.Json.stringify({error: "Unauthorized - Invalid or expired token"}));
					res.end();
					return;
				}
			}
			next();
		});
	}
}
