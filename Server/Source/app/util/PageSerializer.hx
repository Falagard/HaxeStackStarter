package app.util;

import app.models.CmsModels;
import app.models.VisibilityConfig;
// import sidewinder.Database;
import sidewinder.IDatabaseService;
import haxe.Json;
import sidewinder.DI;
import hx.injection.Service;

class PageSerializer implements Service {
	var db:IDatabaseService;

	public function new(?db:IDatabaseService) {
		this.db = db != null ? db : DI.get(IDatabaseService);
	}

	public function updatePageMeta(pageId:Int, title:String, slug:String, ?visibilityConfig:VisibilityConfig):Bool {
		// Validate slug format (only allow a-z, 0-9, dash, underscore, min 3 chars)
		var slugRegex = ~/^[a-z0-9_-]{3,}$/i;
		if (!slugRegex.match(slug)) {
			return false;
		}
		var conn = db.acquire();
		try {
			// Check for duplicate slug (exclude current page)
			var params = new Map<String, Dynamic>();
			params.set("slug", slug);
			params.set("pageId", pageId);
			var sql = "SELECT id FROM pages WHERE slug = @slug AND id != @pageId";
			var rs = conn.request(db.buildSql(sql, params));
			if (rs.hasNext()) {
				db.release(conn);
				return false; // Duplicate found
			}
			// Update title, slug, and visibilityConfig if provided
			params = new Map<String, Dynamic>();
			params.set("pageId", pageId);
			params.set("title", title);
			params.set("slug", slug);
			if (visibilityConfig != null) {
				params.set("visibilityConfig", haxe.Json.stringify(visibilityConfig));
				sql = "UPDATE pages SET title = @title, slug = @slug, visibility_config = @visibilityConfig WHERE id = @pageId";
			} else {
				sql = "UPDATE pages SET title = @title, slug = @slug WHERE id = @pageId";
			}
			conn.request(db.buildSql(sql, params));
			db.release(conn);
			return true;
		} catch (e:Dynamic) {
			db.release(conn);
			return false;
		}
	}

	public function savePageVersion(page:PageDTO, ?userId:String, ?seoHtml:String, ?conn:sys.db.Connection):Int {
		var ownConn = false;
		if (conn == null) {
			conn = db.acquire();
			ownConn = true;
		}
		try {
			// Get next version number
			var params = new Map<String, Dynamic>();
			params.set("pageId", page.pageId);
			var sql = "SELECT COALESCE(MAX(version_num),0)+1 AS nextVer FROM page_versions WHERE page_id = @pageId";
			var rs = conn.request(db.buildSql(sql, params));
			var nextVer = 1;
			if (rs.hasNext()) {
				var rec = rs.next();
				nextVer = rec.nextVer;
			}

			// Insert new version
			params = new Map<String, Dynamic>();
			params.set("pageId", page.pageId);
			params.set("versionNum", nextVer);
			params.set("title", page.title);
			params.set("layout", page.layout);
			params.set("slug", page.slug);
			params.set("createdBy", userId);
			params.set("seoHtml", seoHtml);
			params.set("visibilityConfig",
				haxe.Json.stringify(page.visibilityConfig != null ? page.visibilityConfig : {visibilityMode: "Public", groupIds: []}));
			sql = "INSERT INTO page_versions (page_id, version_num, title, layout, slug, created_by, seo_html, visibility_config) VALUES (@pageId, @versionNum, @title, @layout, @slug, @createdBy, @seoHtml, @visibilityConfig)";
			conn.request(db.buildSql(sql, params));
			var versionId = conn.lastInsertId();

			// Insert components
			for (comp in page.components) {
				var jsonData = Json.stringify(comp.data);
				params = new Map<String, Dynamic>();
				params.set("versionId", versionId);
				params.set("sortOrder", comp.sort);
				params.set("type", comp.type);
				params.set("dataJson", jsonData);
				params.set("visibilityConfig", haxe.Json.stringify(comp.visibilityConfig));
				sql = "INSERT INTO page_components (page_version_id, sort_order, type, data_json, visibility_config) VALUES (@versionId, @sortOrder, @type, @dataJson, @visibilityConfig)";
				conn.request(db.buildSql(sql, params));
			}

			// Update Page latest_version_id and title
			params = new Map<String, Dynamic>();
			params.set("versionId", versionId);
			params.set("pageId", page.pageId);
			params.set("title", page.title);
			sql = "UPDATE pages SET latest_version_id = @versionId, title = @title WHERE id = @pageId";
			conn.request(db.buildSql(sql, params));

			if (ownConn)
				db.release(conn);
			return versionId;
		} catch (e:Dynamic) {
			if (ownConn)
				db.release(conn);
			throw e;
		}
	}

	public function createPage(slug:String, title:String, layout:String = "default", ?seoHtml:String, ?conn:sys.db.Connection):Int {
		var conn = db.acquire();
		try {
			var params = new Map<String, Dynamic>();
			params.set("slug", slug);
			params.set("title", title);
			var sql = "INSERT INTO pages (slug, title) VALUES (@slug, @title)";
			conn.request(db.buildSql(sql, params));
			var pageId = conn.lastInsertId();

			// Create initial empty version
			var page:PageDTO = {
				pageId: pageId,
				title: title,
				layout: layout,
				slug: slug,
				components: [],
				visibilityConfig: {visibilityMode: "Public", groupIds: []}
			};
			var versionId = savePageVersion(page, null, seoHtml, conn);

			// Update Page latest_version_id, published_version_id and title
			params = new Map<String, Dynamic>();
			params.set("versionId", versionId);
			params.set("pageId", pageId);
			params.set("title", title);
			sql = "UPDATE pages SET latest_version_id = @versionId, published_version_id = @versionId, title = @title WHERE id = @pageId";
			conn.request(db.buildSql(sql, params));

			db.release(conn);
			return pageId;
		} catch (e:Dynamic) {
			db.release(conn);
			throw e;
		}
	}

	public function publishVersion(pageId:Int, versionId:Int):Void {
		var conn = db.acquire();
		try {
			var params = new Map<String, Dynamic>();
			params.set("versionId", versionId);
			params.set("pageId", pageId);
			var sql = "UPDATE pages SET published_version_id = @versionId WHERE id = @pageId";
			conn.request(db.buildSql(sql, params));
			db.release(conn);
		} catch (e:Dynamic) {
			db.release(conn);
			throw e;
		}
	}

	public function uploadAsset(pageId:Int, filename:String, mime:String, data:String):Int {
		var conn = db.acquire();
		try {
			// Decode base64 data
			var bytes = haxe.crypto.Base64.decode(data);

			var params = new Map<String, Dynamic>();
			params.set("pageId", pageId);
			params.set("filename", filename);
			params.set("mime", mime);
			params.set("data", bytes.toString());
			var sql = "INSERT INTO page_assets (page_id, filename, mime, data) VALUES (@pageId, @filename, @mime, @data)";
			conn.request(db.buildSql(sql, params));
			var assetId = conn.lastInsertId();

			db.release(conn);
			return assetId;
		} catch (e:Dynamic) {
			db.release(conn);
			throw e;
		}
	}
}
