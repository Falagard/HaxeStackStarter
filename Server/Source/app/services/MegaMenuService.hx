package app.services;

import app.models.VisibilityConfig;
import app.models.MegaMenuModels;
import app.services.IMegaMenuService;
import sidewinder.IDatabaseService;
import sidewinder.DI;
import haxe.Json;

class MegaMenuService implements IMegaMenuService {
	var db:IDatabaseService;

	public function new(?db:IDatabaseService) {
		this.db = db != null ? db : DI.get(IDatabaseService);
	}

	// Menus
	public function listMenus():Array<MenuDTO> {
		var conn = db.acquire();
		try {
			var sql = "SELECT * FROM mega_menus ORDER BY sort_order ASC";
			var rs = conn.request(sql);
			var menus = [];
			while (rs.hasNext()) {
				var rec = rs.next();
				menus.push(recordToMenu(rec));
			}
			db.release(conn);
			return menus;
		} catch (e:Dynamic) {
			db.release(conn);
			throw e;
		}
	}

	public function getMenu(id:Int):MenuDTO {
		var conn = db.acquire();
		try {
			var params = new Map<String, Dynamic>();
			params.set("id", id);
			var sql = "SELECT * FROM mega_menus WHERE id = @id";
			var rs = conn.request(db.buildSql(sql, params));
			if (!rs.hasNext()) {
				db.release(conn);
				throw 'Menu not found: $id';
			}
			var menu = recordToMenu(rs.next());

			// Load sections
			menu.sections = listSections(id);

			db.release(conn);
			return menu;
		} catch (e:Dynamic) {
			db.release(conn);
			throw e;
		}
	}

	public function createMenu(menu:MenuDTO):Int {
		var conn = db.acquire();
		try {
			var params = new Map<String, Dynamic>();
			params.set("name", menu.name);
			params.set("sort_order", menu.sortOrder);
			params.set("visibility_config", haxe.Json.stringify(menu.visibilityConfig));

			var sql = "INSERT INTO mega_menus (name, sort_order, visibility_config) VALUES (@name, @sort_order, @visibility_config)";
			conn.request(db.buildSql(sql, params));
			var id = conn.lastInsertId();
			db.release(conn);
			return id;
		} catch (e:Dynamic) {
			db.release(conn);
			throw e;
		}
	}

	public function updateMenu(id:Int, menu:MenuDTO):Bool {
		var conn = db.acquire();
		try {
			var params = new Map<String, Dynamic>();
			params.set("id", id);
			params.set("name", menu.name);
			params.set("sort_order", menu.sortOrder);
			params.set("visibility_config", haxe.Json.stringify(menu.visibilityConfig));

			var sql = "UPDATE mega_menus SET name = @name, sort_order = @sort_order, visibility_config = @visibility_config WHERE id = @id";
			conn.request(db.buildSql(sql, params));
			db.release(conn);
			return true;
		} catch (e:Dynamic) {
			db.release(conn);
			return false;
		}
	}

	public function deleteMenu(id:Int):Bool {
		var conn = db.acquire();
		try {
			var params = new Map<String, Dynamic>();
			params.set("id", id);
			var sql = "DELETE FROM mega_menus WHERE id = @id";
			conn.request(db.buildSql(sql, params));
			db.release(conn);
			return true;
		} catch (e:Dynamic) {
			db.release(conn);
			return false;
		}
	}

	// Sections
	public function listSections(menuId:Int):Array<MenuSectionDTO> {
		var conn = db.acquire();
		try {
			var params = new Map<String, Dynamic>();
			params.set("menu_id", menuId);
			var sql = "SELECT * FROM mega_menu_sections WHERE menu_id = @menu_id ORDER BY sort_order ASC";
			var rs = conn.request(db.buildSql(sql, params));
			var sections = [];
			while (rs.hasNext()) {
				var rec = rs.next();
				var section = recordToSection(rec);
				section.items = listItems(section.id);
				sections.push(section);
			}
			db.release(conn);
			return sections;
		} catch (e:Dynamic) {
			db.release(conn);
			throw e;
		}
	}

	public function createSection(menuId:Int, section:MenuSectionDTO):Int {
		var conn = db.acquire();
		try {
			var params = new Map<String, Dynamic>();
			params.set("menu_id", menuId);
			params.set("title", section.title);
			params.set("sort_order", section.sortOrder);

			var sql = "INSERT INTO mega_menu_sections (menu_id, title, sort_order) VALUES (@menu_id, @title, @sort_order)";
			conn.request(db.buildSql(sql, params));
			var id = conn.lastInsertId();
			db.release(conn);
			return id;
		} catch (e:Dynamic) {
			db.release(conn);
			throw e;
		}
	}

	public function updateSection(id:Int, section:MenuSectionDTO):Bool {
		var conn = db.acquire();
		try {
			var params = new Map<String, Dynamic>();
			params.set("id", id);
			params.set("title", section.title);
			params.set("sort_order", section.sortOrder);

			var sql = "UPDATE mega_menu_sections SET title = @title, sort_order = @sort_order WHERE id = @id";
			conn.request(db.buildSql(sql, params));
			db.release(conn);
			return true;
		} catch (e:Dynamic) {
			db.release(conn);
			return false;
		}
	}

	public function deleteSection(id:Int):Bool {
		var conn = db.acquire();
		try {
			var params = new Map<String, Dynamic>();
			params.set("id", id);
			var sql = "DELETE FROM mega_menu_sections WHERE id = @id";
			conn.request(db.buildSql(sql, params));
			db.release(conn);
			return true;
		} catch (e:Dynamic) {
			db.release(conn);
			return false;
		}
	}

	// Items
	public function listItems(sectionId:Int):Array<MenuItemDTO> {
		var conn = db.acquire();
		try {
			var params = new Map<String, Dynamic>();
			params.set("section_id", sectionId);
			var sql = "SELECT * FROM mega_menu_items WHERE section_id = @section_id ORDER BY sort_order ASC";
			var rs = conn.request(db.buildSql(sql, params));
			var items = [];
			while (rs.hasNext()) {
				var rec = rs.next();
				items.push(recordToItem(rec));
			}
			db.release(conn);
			return items;
		} catch (e:Dynamic) {
			db.release(conn);
			throw e;
		}
	}

	public function createItem(sectionId:Int, item:MenuItemDTO):Int {
		var conn = db.acquire();
		try {
			var params = new Map<String, Dynamic>();
			params.set("section_id", sectionId);
			params.set("label", item.label);
			params.set("description", item.description);
			params.set("url", item.url);
			params.set("icon", item.icon);
			params.set("item_type", item.itemType);
			params.set("custom_component", item.customComponent);
			params.set("sort_order", item.sortOrder);
			params.set("visibility_config", haxe.Json.stringify(item.visibilityConfig));

			var sql = "INSERT INTO mega_menu_items (section_id, label, description, url, icon, item_type, custom_component, sort_order, visibility_config) VALUES (@section_id, @label, @description, @url, @icon, @item_type, @custom_component, @sort_order, @visibility_config)";
			conn.request(db.buildSql(sql, params));
			var id = conn.lastInsertId();
			db.release(conn);
			return id;
		} catch (e:Dynamic) {
			db.release(conn);
			throw e;
		}
	}

	public function updateItem(id:Int, item:MenuItemDTO):Bool {
		var conn = db.acquire();
		try {
			var params = new Map<String, Dynamic>();
			params.set("id", id);
			params.set("label", item.label);
			params.set("description", item.description);
			params.set("url", item.url);
			params.set("icon", item.icon);
			params.set("item_type", item.itemType);
			params.set("custom_component", item.customComponent);
			params.set("sort_order", item.sortOrder);
			params.set("visibility_config", haxe.Json.stringify(item.visibilityConfig));

			var sql = "UPDATE mega_menu_items SET label = @label, description = @description, url = @url, icon = @icon, item_type = @item_type, custom_component = @custom_component, sort_order = @sort_order, visibility_config = @visibility_config WHERE id = @id";
			conn.request(db.buildSql(sql, params));
			db.release(conn);
			return true;
		} catch (e:Dynamic) {
			db.release(conn);
			return false;
		}
	}

	public function deleteItem(id:Int):Bool {
		var conn = db.acquire();
		try {
			var params = new Map<String, Dynamic>();
			params.set("id", id);
			var sql = "DELETE FROM mega_menu_items WHERE id = @id";
			conn.request(db.buildSql(sql, params));
			db.release(conn);
			return true;
		} catch (e:Dynamic) {
			db.release(conn);
			return false;
		}
	}

	// Metadata
	public function listMetadata(itemId:Int):Array<MenuItemMetadataDTO> {
		var conn = db.acquire();
		try {
			var params = new Map<String, Dynamic>();
			params.set("item_id", itemId);
			var sql = "SELECT * FROM mega_menu_item_metadata WHERE item_id = @item_id";
			var rs = conn.request(db.buildSql(sql, params));
			var metadata = [];
			while (rs.hasNext()) {
				var meta = rs.next();
				metadata.push({
					id: Std.int(meta.id),
					itemId: Std.int(meta.item_id),
					keyName: Std.string(meta.key_name),
					value: Std.string(meta.value)
				});
			}
			db.release(conn);
			return metadata;
		} catch (e:Dynamic) {
			db.release(conn);
			throw e;
		}
	}

	public function createMetadata(itemId:Int, metadata:MenuItemMetadataDTO):Int {
		var conn = db.acquire();
		try {
			var params = new Map<String, Dynamic>();
			params.set("item_id", itemId);
			params.set("key_name", metadata.keyName);
			params.set("value", metadata.value);
			var sql = "INSERT INTO mega_menu_item_metadata (item_id, key_name, value) VALUES (@item_id, @key_name, @value)";
			conn.request(db.buildSql(sql, params));
			var id = conn.lastInsertId();
			db.release(conn);
			return id;
		} catch (e:Dynamic) {
			db.release(conn);
			throw e;
		}
	}

	public function updateMetadata(id:Int, metadata:MenuItemMetadataDTO):Bool {
		var conn = db.acquire();
		try {
			var params = new Map<String, Dynamic>();
			params.set("id", id);
			params.set("key_name", metadata.keyName);
			params.set("value", metadata.value);
			var sql = "UPDATE mega_menu_item_metadata SET key_name = @key_name, value = @value WHERE id = @id";
			conn.request(db.buildSql(sql, params));
			db.release(conn);
			return true;
		} catch (e:Dynamic) {
			db.release(conn);
			return false;
		}
	}

	public function deleteMetadata(id:Int):Bool {
		var conn = db.acquire();
		try {
			var params = new Map<String, Dynamic>();
			params.set("id", id);
			var sql = "DELETE FROM mega_menu_item_metadata WHERE id = @id";
			conn.request(db.buildSql(sql, params));
			db.release(conn);
			return true;
		} catch (e:Dynamic) {
			db.release(conn);
			return false;
		}
	}

	// Helper builders
	private function recordToMenu(menu:Dynamic):MenuDTO {
		return {
			id: Std.int(menu.id),
			name: Std.string(menu.name),
			slug: Std.string(menu.slug),
			icon: Std.string(menu.icon),
			sortOrder: Std.int(menu.sort_order),
			enabled: menu.enabled == 1,
			sections: listSections(menu.id),
			visibilityConfig: menu.visibilityConfig != null ? haxe.Json.parse(menu.visibilityConfig) : {
				visibilityMode: "Public",
				groupIds: []
			}
		};
	}

	private function recordToSection(section:Dynamic):MenuSectionDTO {
		return {
			id: Std.int(section.id),
			menuId: Std.int(section.menu_id),
			title: Std.string(section.title != null ? section.title : section.name),
			layoutType: Std.string(section.layout_type),
			sortOrder: Std.int(section.sort_order),
			enabled: section.enabled == 1,
			items: listItems(section.id)
		};
	}

	private function recordToItem(item:Dynamic):MenuItemDTO {
		return {
			id: Std.int(item.id),
			sectionId: Std.int(item.section_id),
			label: Std.string(item.label),
			description: Std.string(item.description),
			url: Std.string(item.url),
			icon: Std.string(item.icon),
			itemType: Std.string(item.item_type),
			customComponent: Std.string(item.custom_component),
			sortOrder: Std.int(item.sort_order),
			enabled: item.enabled == 1,
			metadata: listMetadata(item.id),
			visibilityConfig: item.visibilityConfig != null ? haxe.Json.parse(item.visibilityConfig) : {
				visibilityMode: "Public",
				groupIds: []
			}
		};
	}
}
