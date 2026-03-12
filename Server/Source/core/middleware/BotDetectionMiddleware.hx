package core.middleware;

import sidewinder.core.App;
import sidewinder.core.DI;
import app.services.ICmsService;
import snake.http.HTTPStatus;

class BotDetectionMiddleware {
	public static function use() {
		App.use((req, res, next) -> {
			var botRegex = ~/bot|crawl|spider|slurp|bing|duckduck|baidu|yandex|sogou|exabot|facebot|ia_archiver/i;
			var userAgent = req.headers.get("User-Agent");
			var spaMatch = ~/^\/static\/client\/index\.html#(.+)/;

			if (userAgent != null && botRegex.match(userAgent) && spaMatch.match(req.path)) {
				var pageId = spaMatch.matched(1);
				// TODO: Make ICmsService generic or configurable?
				// For now assuming ICmsService is available via DI since this is CMS-specific middleware
				// or core middleware that knows about CMS via interface
				try {
					var cms:ICmsService = cast DI.get(ICmsService);
					if (cms != null) {
						var pageResp = cms.getPage(Std.parseInt(pageId));
						var slug = pageResp != null
							&& pageResp.success
							&& pageResp.page != null
							&& Reflect.hasField(pageResp.page, "slug") ? Reflect.field(pageResp.page, "slug") : pageId;
						var seoUrl = '/seo/' + slug;
						res.sendResponse(HTTPStatus.FOUND); // 302
						res.setHeader("Location", seoUrl);
						res.endHeaders();
						res.write('Redirecting bot to SEO page...');
						res.end();
						return;
					}
				} catch (e:Dynamic) {}
			}
			next();
		});
	}
}
