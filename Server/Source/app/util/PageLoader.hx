package app.util;

import app.models.CmsModels;
// import sidewinder.Database;
import sidewinder.IDatabaseService;
import haxe.Json;
import sidewinder.DI;
import hx.injection.Service;

class PageLoader implements Service {
	var db:IDatabaseService;

	public function new(?db:IDatabaseService) {
		this.db = db != null ? db : DI.get(IDatabaseService);
	}

	public function loadLatest(pageId:Int, ?conn:sys.db.Connection):PageVersionDTO {
		var ownConn = false;
		if (conn == null) {
			conn = db.acquire();
			ownConn = true;
		}
		try {
			var params = new Map<String, Dynamic>();
			params.set("pageId", pageId);
			var sql = "SELECT latest_version_id FROM pages WHERE id = @pageId";
			var rs = conn.request(db.buildSql(sql, params));
			if (!rs.hasNext()) {
				if (ownConn)
					db.release(conn);
				throw 'Page not found: $pageId';
			}
			var rec = rs.next();
			var versionIdField = Reflect.field(rec, "latest_version_id");
			var versionId = versionIdField != null ? Std.int(versionIdField) : 0;
			if (versionId == 0) {
				if (ownConn)
					db.release(conn);
				throw 'Page has no latest version: $pageId';
			}
			var result = loadVersion(versionId, conn);
			if (ownConn)
				db.release(conn);
			return result;
		} catch (e:Dynamic) {
			if (ownConn)
				db.release(conn);
			throw e;
		}
	}

	public function loadPublished(pageId:Int, ?conn:sys.db.Connection):PageVersionDTO {
		var ownConn = false;
		if (conn == null) {
			conn = db.acquire();
			ownConn = true;
		}
		try {
			var params = new Map<String, Dynamic>();
			params.set("pageId", pageId);
			var sql = "SELECT published_version_id FROM pages WHERE id = @pageId";
			var rs = conn.request(db.buildSql(sql, params));
			if (!rs.hasNext()) {
				if (ownConn)
					db.release(conn);
				throw 'Page not found: $pageId';
			}
			var rec = rs.next();
			var versionIdField = Reflect.field(rec, "published_version_id");
			var versionId = versionIdField != null ? Std.int(versionIdField) : 0;
			if (versionId == 0) {
				if (ownConn)
					db.release(conn);
				throw 'Page has no published version: $pageId';
			}
			var result = loadVersion(versionId, conn);
			if (ownConn)
				db.release(conn);
			return result;
		} catch (e:Dynamic) {
			if (ownConn)
				db.release(conn);
			throw e;
		}
	}

	public function loadBySlug(slug:String, published:Bool = true, ?conn:sys.db.Connection):PageVersionDTO {
		var ownConn = false;
		if (conn == null) {
			conn = db.acquire();
			ownConn = true;
		}
		try {
			var params = new Map<String, Dynamic>();
			params.set("slug", slug);
			var column = published ? "published_version_id" : "latest_version_id";
			var sql = 'SELECT id, $column FROM pages WHERE slug = @slug';
			var rs = conn.request(db.buildSql(sql, params));
			if (!rs.hasNext()) {
				if (ownConn)
					db.release(conn);
				throw 'Page not found: $slug';
			}
			var rec = rs.next();
			var versionIdField = Reflect.field(rec, column);
			var versionId = versionIdField != null ? Std.int(versionIdField) : 0;
			if (versionId == 0) {
				if (ownConn)
					db.release(conn);
				throw 'Page has no ${published ? "published" : "latest"} version: $slug';
			}
			var result = loadVersion(versionId, conn);
			if (ownConn)
				db.release(conn);
			return result;
		} catch (e:Dynamic) {
			if (ownConn)
				db.release(conn);
			throw e;
		}
	}

	public function loadVersion(versionId:Int, ?conn:sys.db.Connection):PageVersionDTO {
		if (versionId == 0) {
			throw 'Invalid version ID: 0';
		}
		var ownConn = false;
		if (conn == null) {
			conn = db.acquire();
			ownConn = true;
		}
		try {
			var params = new Map<String, Dynamic>();
			params.set("versionId", versionId);
			var sql = "SELECT id, page_id, version_num, title, layout, slug, created_at, created_by, seo_html, visibility_config FROM page_versions WHERE id = @versionId";
			var rs = conn.request(db.buildSql(sql, params));
			if (!rs.hasNext()) {
				if (ownConn)
					db.release(conn);
				throw 'Version not found: $versionId';
			}
			var v = rs.next();
			var dto:PageVersionDTO = {
				id: Std.int(Reflect.field(v, "id")),
				pageId: Std.int(Reflect.field(v, "page_id")),
				versionNum: Std.int(Reflect.field(v, "version_num")),
				title: Std.string(Reflect.field(v, "title")),
				layout: Std.string(Reflect.field(v, "layout")),
				slug: Std.string(Reflect.field(v, "slug")),
				createdAt: Date.fromString(Std.string(Reflect.field(v, "created_at"))),
				createdBy: Std.string(Reflect.field(v, "created_by")),
				components: [],
				seoHtml: Std.string(Reflect.field(v, "seo_html")),
				visibilityConfig: Reflect.field(v, "visibility_config") != null ? haxe.Json.parse(Std.string(Reflect.field(v, "visibility_config"))) : {
					visibilityMode: "Public",
					groupIds: []
				}
			};

			params = new Map<String, Dynamic>();
			params.set("versionId", versionId);
			sql = "SELECT id, sort_order, type, data_json, visibility_config FROM page_components WHERE page_version_id = @versionId ORDER BY sort_order ASC";
			var rs2 = conn.request(db.buildSql(sql, params));
			while (rs2.hasNext()) {
				var c = rs2.next();
				dto.components.push({
					id: Std.int(Reflect.field(c, "id")),
					sort: Std.int(Reflect.field(c, "sort_order")),
					type: Std.string(Reflect.field(c, "type")),
					data: Json.parse(Std.string(Reflect.field(c, "data_json"))),
					visibilityConfig: Reflect.field(c, "visibility_config") != null ? haxe.Json.parse(Std.string(Reflect.field(c, "visibility_config"))) : {
						visibilityMode: "Public",
						groupIds: []
					}
				});
			}

			if (ownConn)
				db.release(conn);
			return dto;
		} catch (e:Dynamic) {
			if (ownConn)
				db.release(conn);
			throw e;
		}
	}

	public function listVersions(pageId:Int):Array<{
		id:Int,
		versionNum:Int,
		createdAt:Date,
		createdBy:String
	}> {
		var conn = db.acquire();
		try {
			var params = new Map<String, Dynamic>();
			params.set("pageId", pageId);
			var sql = "SELECT id, version_num, created_at, created_by FROM page_versions WHERE page_id = @pageId ORDER BY version_num DESC";
			var rs = conn.request(db.buildSql(sql, params));
			var versions = [];
			while (rs.hasNext()) {
				var rec = rs.next();
				versions.push({
					id: Std.int(Reflect.field(rec, "id")),
					versionNum: Std.int(Reflect.field(rec, "version_num")),
					createdAt: Date.fromString(Std.string(Reflect.field(rec, "created_at"))),
					createdBy: Std.string(Reflect.field(rec, "created_by"))
				});
			}
			db.release(conn);
			return versions;
		} catch (e:Dynamic) {
			db.release(conn);
			throw e;
		}
	}

	public function listPages():Array<PageListItem> {
		var conn = db.acquire();
		try {
			var sql = "SELECT id, slug, title, created_at FROM pages ORDER BY created_at DESC";
			var rs = conn.request(sql);
			var pages = [];
			while (rs.hasNext()) {
				var rec = rs.next();
				pages.push({
					id: Std.int(Reflect.field(rec, "id")),
					slug: Std.string(Reflect.field(rec, "slug")),
					title: Std.string(Reflect.field(rec, "title")),
					createdAt: Date.fromString(Std.string(Reflect.field(rec, "created_at")))
				});
			}
			db.release(conn);
			return pages;
		} catch (e:Dynamic) {
			db.release(conn);
			throw e;
		}
	}

	public function getAsset(assetId:Int):{filename:String, mime:String, data:String} {
		var conn = db.acquire();
		try {
			var params = new Map<String, Dynamic>();
			params.set("assetId", assetId);
			var sql = "SELECT filename, mime, data FROM page_assets WHERE id = @assetId";
			var rs = conn.request(db.buildSql(sql, params));
			if (!rs.hasNext()) {
				db.release(conn);
				throw 'Asset not found: $assetId';
			}
			var rec = rs.next();
			var result = {
				filename: Std.string(Reflect.field(rec, "filename")),
				mime: Std.string(Reflect.field(rec, "mime")),
				data: Std.string(Reflect.field(rec, "data"))
			};
			db.release(conn);
			return result;
		} catch (e:Dynamic) {
			db.release(conn);
			throw e;
		}
	}

	public function listAssets(pageId:Int):Array<PageAssetDTO> {
		var conn = db.acquire();
		try {
			var params = new Map<String, Dynamic>();
			params.set("pageId", pageId);
			var sql = "SELECT id, page_id, filename, mime, created_at FROM page_assets WHERE page_id = @pageId ORDER BY created_at DESC";
			var rs = conn.request(db.buildSql(sql, params));
			var assets = [];
			while (rs.hasNext()) {
				var rec = rs.next();
				assets.push({
					id: Std.int(Reflect.field(rec, "id")),
					pageId: Std.int(Reflect.field(rec, "page_id")),
					filename: Std.string(Reflect.field(rec, "filename")),
					mime: Std.string(Reflect.field(rec, "mime")),
					createdAt: Date.fromString(Std.string(Reflect.field(rec, "created_at")))
				});
			}
			db.release(conn);
			return assets;
		} catch (e:Dynamic) {
			db.release(conn);
			throw e;
		}
	}
}
