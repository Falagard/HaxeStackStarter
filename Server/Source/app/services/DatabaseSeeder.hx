package app.services;

import sidewinder.IDatabaseService;
import sidewinder.HybridLogger;
import sidewinder.DI;
import app.services.IAuthService;
import app.services.ICmsService;
import app.models.AuthModels.RegisterRequest;
import app.models.CmsModels.CreatePageRequest;
import hx.injection.Service;

class DatabaseSeeder implements Service {
	var db:IDatabaseService;
	var auth:IAuthService;
	var cms:ICmsService;

	public function new(?db:IDatabaseService, ?auth:IAuthService, ?cms:ICmsService) {
		this.db = db != null ? db : DI.get(IDatabaseService);
		this.auth = auth != null ? auth : DI.get(IAuthService);
		this.cms = cms != null ? cms : DI.get(ICmsService);
	}

	public function seed():Void {
		var userId:String = null;

		if (shouldSeedUsers()) {
			userId = seedUsers();
		} else {
			userId = getFirstUser();
		}

		if (userId != null && shouldSeedPages()) {
			seedPages(userId);
		}
	}

	private function shouldSeedUsers():Bool {
		try {
			var conn = db.acquire();
			var rs = conn.request("SELECT count(*) as count FROM users");
			var count = 0;
			if (rs.hasNext()) {
				var row = rs.next();
				count = Std.int(Reflect.field(row, "count"));
			}
			db.release(conn);
			return count == 0;
		} catch (e:Dynamic) {
			HybridLogger.error("Failed to check users table: " + e);
			return false;
		}
	}

	private function shouldSeedPages():Bool {
		try {
			var conn = db.acquire();
			var rs = conn.request("SELECT count(*) as count FROM pages");
			var count = 0;
			if (rs.hasNext()) {
				var row = rs.next();
				count = Std.int(Reflect.field(row, "count"));
			}
			db.release(conn);
			return count == 0;
		} catch (e:Dynamic) {
			HybridLogger.error("Failed to check pages table: " + e);
			return false;
		}
	}

	private function getFirstUser():String {
		try {
			var conn = db.acquire();
			var rs = conn.request("SELECT id FROM users ORDER BY created_at ASC LIMIT 1");
			var id:String = null;
			if (rs.hasNext()) {
				var row = rs.next();
				id = Std.string(Reflect.field(row, "id"));
			}
			db.release(conn);
			return id;
		} catch (e:Dynamic) {
			HybridLogger.error("Failed to fetch first user: " + e);
			return null;
		}
	}

	private function seedUsers():String {
		HybridLogger.info("Seeding default admin user...");
		var request:RegisterRequest = {
			email: "admin@example.com",
			password: "SideWinder2024!",
			username: "admin"
		};

		var response = auth.register(request);
		if (response.success) {
			HybridLogger.info("Admin user created successfully.");
			return response.user.id;
		} else {
			HybridLogger.error("Failed to create admin user: " + response.error);
			return null;
		}
	}

	private function seedPages(userId:String):Void {
		HybridLogger.info("Seeding default home page...");
		var request:CreatePageRequest = {
			slug: "home",
			title: "Home",
			layout: "default",
			seoHtml: "<h1>Welcome to SideWinder</h1><p>This is your new home page.</p>"
		};

		var response = cms.createPage(request, userId);
		if (response.success) {
			HybridLogger.info("Home page created successfully.");
		} else {
			HybridLogger.error("Failed to create home page: " + response.error);
		}
	}
}
