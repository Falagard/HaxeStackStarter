package core.middleware;

import sidewinder.core.App;
import sidewinder.core.DI;
import sidewinder.interfaces.ICacheService;
import app.services.IAuthService;
import snake.http.HTTPStatus;
import haxe.Json;

class AuthenticationMiddleware {
	public static function use(cache:ICacheService) {
		App.use((req, res, next) -> {
			// Check authentication for all /api/ routes
			if (req.path.indexOf("/api/") == 0) {
				var sessionToken:String = null;
				var authHeader = req.headers.get("Authorization");

				if (authHeader != null && authHeader.indexOf("Bearer ") == 0) {
					sessionToken = authHeader.substring(7);
				}

				if (sessionToken == null && req.cookies != null && req.cookies.exists("session_token")) {
					sessionToken = req.cookies.get("session_token");
				}

				var user = null;
				if (sessionToken != null) {
					var cachedUser = cache.get("session:" + sessionToken);
					if (cachedUser != null) {
						user = cachedUser;
					} else {
						var authService:app.services.AuthService = cast DI.get(IAuthService);
						user = authService.validateSessionToken(sessionToken);

						if (user != null) {
							cache.set("session:" + sessionToken, user, 604800);
						}
					}
				}

				// Set user in request context for downstream use
				// Using req.params as a transport mechanism since Request is not dynamic
				if (user != null) {
					var userJson = haxe.Json.stringify(user);
					req.params.set("auth_user_json", userJson);
				}

				// Enforce authentication for non-auth endpoints
				if (req.path.indexOf("/api/auth/") != 0) {
					if (user == null) {
						res.sendResponse(HTTPStatus.UNAUTHORIZED);
						res.setHeader("Content-Type", "application/json");
						res.endHeaders();
						res.write(haxe.Json.stringify({error: "Unauthorized - Invalid or expired token"}));
						res.end();
						return;
					}
				}
			}
			next();
		});
	}
}
