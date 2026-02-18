package app.services;

import app.models.CmsModels;
import app.models.AuthModels;
import app.models.MegaMenuModels;
import app.services.ICmsService;
import app.services.IMegaMenuService;
import app.services.IAuthService;
import sidewinder.HybridLogger;
import hx.injection.Service;

class DatabaseSeeder implements Service {
	var cms:ICmsService;
	var megaMenu:IMegaMenuService;
	var auth:IAuthService;

	public function new(?cms:ICmsService, ?megaMenu:IMegaMenuService, ?auth:IAuthService) {
		this.cms = cms != null ? cms : sidewinder.DI.get(ICmsService);
		this.megaMenu = megaMenu != null ? megaMenu : sidewinder.DI.get(IMegaMenuService);
		this.auth = auth != null ? auth : sidewinder.DI.get(IAuthService);
	}

	public function seed():Void {
		HybridLogger.info("DatabaseSeeder.seed() called");
		var userId:String = "";
		if (shouldSeedUsers()) {
			userId = seedUsers();
		} else {
			userId = getFirstUser();
		}

		if (userId != "" && userId != null) {
			if (shouldSeedPages()) {
				seedPages(userId);
			}
			seedMegaMenus();
		}
	}

	private function shouldSeedUsers():Bool {
		var conn = sidewinder.DI.get(sidewinder.IDatabaseService).acquire();
		try {
			var rs = conn.request("SELECT COUNT(*) as count FROM users");
			var count = rs.hasNext() ? rs.next().count : 0;
			sidewinder.DI.get(sidewinder.IDatabaseService).release(conn);
			return count == 0;
		} catch (e:Dynamic) {
			sidewinder.DI.get(sidewinder.IDatabaseService).release(conn);
			return true;
		}
	}

	private function getFirstUser():String {
		var conn = sidewinder.DI.get(sidewinder.IDatabaseService).acquire();
		try {
			var rs = conn.request("SELECT id FROM users LIMIT 1");
			var id = rs.hasNext() ? Std.string(rs.next().id) : "";
			sidewinder.DI.get(sidewinder.IDatabaseService).release(conn);
			return id;
		} catch (e:Dynamic) {
			sidewinder.DI.get(sidewinder.IDatabaseService).release(conn);
			return "";
		}
	}

	private function seedUsers():String {
		var request:RegisterRequest = {
			email: "admin@example.com",
			password: "password123",
			username: "Admin User"
		};
		var response = auth.register(request);
		if (response.success && response.user != null) {
			return response.user.id;
		}
		return "";
	}

	private function shouldSeedPages():Bool {
		var conn = sidewinder.DI.get(sidewinder.IDatabaseService).acquire();
		try {
			var rs = conn.request("SELECT COUNT(*) as count FROM pages");
			var count = rs.hasNext() ? rs.next().count : 0;
			sidewinder.DI.get(sidewinder.IDatabaseService).release(conn);
			return count == 0;
		} catch (e:Dynamic) {
			sidewinder.DI.get(sidewinder.IDatabaseService).release(conn);
			return true;
		}
	}

	private function seedPages(userId:String):Void {
		ensurePage(userId, "home", "Home", "<h1>Welcome to HaxeStack</h1><p>Building modern web apps with Haxe.</p>");
		ensurePage(userId, "products/haxestack", "HaxeStack Framework", "<h1>HaxeStack</h1><p>The ultimate full-stack framework for Haxe developers.</p>");
		ensurePage(userId, "products/sidewinder", "SideWinder Engine", "<h1>SideWinder</h1><p>A high-performance web engine and reactive framework.</p>");
		ensurePage(userId, "docs", "Documentation", "<h1>Documentation</h1><p>Learn how to build brilliant applications with HaxeStack.</p>");
		ensurePage(userId, "blog", "Blog", "<h1>HaxeStack Blog</h1><p>Latest news and updates from the HaxeStack team.</p>");
		ensurePage(userId, "company/about", "About Us", "<h1>About Us</h1><p>We are a team of passionate developers building the future of Haxe.</p>");
		ensurePage(userId, "company/contact", "Contact", "<h1>Contact</h1><p>Get in touch with us for support or business inquiries.</p>");
		ensurePage(userId, "legal/privacy", "Privacy Policy",
			"<h1>Privacy Policy</h1><p>Your privacy is important to us. This policy explains how we handle your data.</p>");
		ensurePage(userId, "legal/terms", "Terms of Service", "<h1>Terms of Service</h1><p>Rules and guidelines for using the HaxeStack platform.</p>");
	}

	private function ensurePage(userId:String, slug:String, title:String, content:String):Void {
		var request:CreatePageRequest = {
			slug: slug,
			title: title,
			layout: "default",
			seoHtml: content
		};
		cms.createPage(request, userId);
	}

	private function seedMegaMenus():Void {
		try {
			var menusList = megaMenu.listMenus();
			if (menusList.length > 1)
				return;

			HybridLogger.info("Seeding mega menus...");

			// --- Main Menu ---
			var mainMenuId = megaMenu.createMenu({
				id: 0,
				name: "Main Menu",
				slug: "main-menu",
				icon: "fa-bars",
				sortOrder: 0,
				enabled: true,
				sections: [],
				visibilityConfig: null
			});

			if (mainMenuId > 0) {
				var productsId = ensureSection(mainMenuId, "Products", "cal-3", 0);
				ensureItem(productsId, "HaxeStack", "Full-stack framework", "#/products/haxestack", "fa-layer-group", 0, 2);
				ensureItem(productsId, "SideWinder", "Web engine", "#/products/sidewinder", "fa-wind", 1, 3);

				var resourcesId = ensureSection(mainMenuId, "Resources", "cal-3", 1);
				ensureItem(resourcesId, "Documentation", "Guides and API", "#/docs", "fa-book", 0, 4);
				ensureItem(resourcesId, "Blog", "Latest news", "#/blog", "fa-rss", 1, 5);

				var companyId = ensureSection(mainMenuId, "Company", "cal-3", 2);
				ensureItem(companyId, "About Us", "Our mission", "#/company/about", "fa-users", 0, 6);
				ensureItem(companyId, "Contact", "Get in touch", "#/company/contact", "fa-envelope", 1, 7);
			}

			// --- Footer Menu ---
			var footerMenuId = megaMenu.createMenu({
				id: 0,
				name: "Footer Menu",
				slug: "footer-menu",
				icon: "fa-info",
				sortOrder: 1,
				enabled: true,
				sections: [],
				visibilityConfig: null
			});

			if (footerMenuId > 0) {
				var legalId = ensureSection(footerMenuId, "Legal", "simple", 0);
				ensureItem(legalId, "Privacy Policy", "", "#/legal/privacy", "fa-shield-alt", 0, 8);
				ensureItem(legalId, "Terms of Service", "", "#/legal/terms", "fa-gavel", 1, 9);

				var socialId = ensureSection(footerMenuId, "Social", "simple", 1);
				ensureItem(socialId, "Twitter", "", "https://twitter.com/haxestack", "fa-twitter", 0);
				ensureItem(socialId, "GitHub", "", "https://github.com/haxestack", "fa-github", 1);
			}
		} catch (e:Dynamic) {
			HybridLogger.error("Error seeding mega menus: " + Std.string(e));
		}
	}

	private function ensureSection(menuId:Int, title:String, layoutType:String, sortOrder:Int):Int {
		return megaMenu.createSection(menuId, {
			id: 0,
			menuId: menuId,
			title: title,
			layoutType: layoutType,
			sortOrder: sortOrder,
			enabled: true,
			items: []
		});
	}

	private function ensureItem(sectionId:Int, label:String, description:String, url:String, icon:String, sortOrder:Int, ?pageId:Int):Int {
		var itemId = megaMenu.createItem(sectionId, {
			id: 0,
			sectionId: sectionId,
			label: label,
			description: description,
			url: url,
			icon: icon,
			itemType: "link",
			customComponent: "",
			sortOrder: sortOrder,
			enabled: true,
			metadata: [],
			visibilityConfig: null
		});
		if (pageId != null) {
			megaMenu.createMetadata(itemId, {
				id: 0,
				itemId: itemId,
				keyName: "pageId",
				value: Std.string(pageId)
			});
		}
		return itemId;
	}
}
