package app.services;

import app.models.MegaMenuModels;
import app.services.IMegaMenuService;
import sidewinder.IDatabaseService;
import sidewinder.HybridLogger;

class MegaMenuService implements IMegaMenuService {
	var db:IDatabaseService;

	public function new(?db:IDatabaseService) {
		this.db = db != null ? db : sidewinder.DI.get(IDatabaseService);
	}

	// ---- Helper to build Map<String,Dynamic> from key-value pairs ----
	private function makeParams(pairs:Array<Dynamic>):Map<String, Dynamic> {
		var m = new Map<String, Dynamic>();
		var i = 0;
		while (i < pairs.length - 1) {
			m.set(Std.string(pairs[i]), pairs[i + 1]);
			i += 2;
		}
		return m;
	}

	// ==================== Menus ====================

	public function listMenus():Array<MenuDTO> {
		var conn = db.acquire();
		try {
			var rs = conn.request("SELECT * FROM menus ORDER BY sort_order ASC");
			var records:Array<Dynamic> = [];
			while (rs.hasNext())
				records.push(rs.next());
			db.release(conn);

			var result:Array<MenuDTO> = [];
			for (rec in records)
				result.push(buildMenu(rec));
			return result;
		} catch (e:Dynamic) {
			db.release(conn);
			throw e;
		}
	}

	public function getMenu(id:Int):MenuDTO {
		var conn = db.acquire();
		try {
			var rs = conn.request('SELECT * FROM menus WHERE id = $id');
			if (!rs.hasNext()) {
				db.release(conn);
				return null;
			}
			var rec = rs.next();
			db.release(conn);
			return buildMenu(rec);
		} catch (e:Dynamic) {
			db.release(conn);
			throw e;
		}
	}

	public function createMenu(menu:MenuDTO):Int {
		var conn = db.acquire();
		try {
			var p = makeParams([
				"name",
				menu.name,
				"slug",
				menu.slug,
				"icon",
				menu.icon,
				"sortOrder",
				menu.sortOrder,
				"enabled",
				menu.enabled ? 1 : 0
			]);
			conn.request(db.buildSql("INSERT INTO menus (name, slug, icon, sort_order, enabled) VALUES (@name, @slug, @icon, @sortOrder, @enabled)", p));
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
			var p = makeParams([
				"id",
				id,
				"name",
				menu.name,
				"slug",
				menu.slug,
				"icon",
				menu.icon,
				"sortOrder",
				menu.sortOrder,
				"enabled",
				menu.enabled ? 1 : 0
			]);
			conn.request(db.buildSql("UPDATE menus SET name = @name, slug = @slug, icon = @icon, sort_order = @sortOrder, enabled = @enabled WHERE id = @id",
				p));
			db.release(conn);
			return true;
		} catch (e:Dynamic) {
			db.release(conn);
			throw e;
		}
	}

	public function deleteMenu(id:Int):Bool {
		var conn = db.acquire();
		try {
			conn.request('DELETE FROM menus WHERE id = $id');
			db.release(conn);
			return true;
		} catch (e:Dynamic) {
			db.release(conn);
			throw e;
		}
	}

	// ==================== Sections ====================

	public function listSections(menuId:Int):Array<MenuSectionDTO> {
		return fetchSections(menuId);
	}

	public function createSection(menuId:Int, section:MenuSectionDTO):Int {
		var conn = db.acquire();
		try {
			var p = makeParams([
				"menuId",
				menuId,
				"title",
				section.title,
				"layoutType",
				section.layoutType,
				"sortOrder",
				section.sortOrder,
				"enabled",
				section.enabled ? 1 : 0
			]);
			conn.request(db.buildSql("INSERT INTO menu_sections (menu_id, title, layout_type, sort_order, enabled) VALUES (@menuId, @title, @layoutType, @sortOrder, @enabled)",
				p));
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
			var p = makeParams([
				"id",
				id,
				"title",
				section.title,
				"layoutType",
				section.layoutType,
				"sortOrder",
				section.sortOrder,
				"enabled",
				section.enabled ? 1 : 0
			]);
			conn.request(db.buildSql("UPDATE menu_sections SET title = @title, layout_type = @layoutType, sort_order = @sortOrder, enabled = @enabled WHERE id = @id",
				p));
			db.release(conn);
			return true;
		} catch (e:Dynamic) {
			db.release(conn);
			throw e;
		}
	}

	public function deleteSection(id:Int):Bool {
		var conn = db.acquire();
		try {
			conn.request('DELETE FROM menu_sections WHERE id = $id');
			db.release(conn);
			return true;
		} catch (e:Dynamic) {
			db.release(conn);
			throw e;
		}
	}

	// ==================== Items ====================

	public function listItems(sectionId:Int):Array<MenuItemDTO> {
		return fetchItems(sectionId);
	}

	public function createItem(sectionId:Int, item:MenuItemDTO):Int {
		var conn = db.acquire();
		try {
			var p = makeParams([
				      "sectionId",            sectionId,
				          "label",           item.label,
				    "description",     item.description,
				            "url",             item.url,
				           "icon",            item.icon,
				       "itemType",        item.itemType,
				"customComponent", item.customComponent,
				      "sortOrder",       item.sortOrder,
				        "enabled", item.enabled ? 1 : 0
			]);
			conn.request(db.buildSql("INSERT INTO menu_items (section_id, label, description, url, icon, item_type, custom_component, sort_order, enabled) VALUES (@sectionId, @label, @description, @url, @icon, @itemType, @customComponent, @sortOrder, @enabled)",
				p));
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
			var p = makeParams([
				             "id",                   id,
				          "label",           item.label,
				    "description",     item.description,
				            "url",             item.url,
				           "icon",            item.icon,
				       "itemType",        item.itemType,
				"customComponent", item.customComponent,
				      "sortOrder",       item.sortOrder,
				        "enabled", item.enabled ? 1 : 0
			]);
			conn.request(db.buildSql("UPDATE menu_items SET label = @label, description = @description, url = @url, icon = @icon, item_type = @itemType, custom_component = @customComponent, sort_order = @sortOrder, enabled = @enabled WHERE id = @id",
				p));
			db.release(conn);
			return true;
		} catch (e:Dynamic) {
			db.release(conn);
			throw e;
		}
	}

	public function deleteItem(id:Int):Bool {
		var conn = db.acquire();
		try {
			conn.request('DELETE FROM menu_items WHERE id = $id');
			db.release(conn);
			return true;
		} catch (e:Dynamic) {
			db.release(conn);
			throw e;
		}
	}

	// ==================== Metadata ====================

	public function listMetadata(itemId:Int):Array<MenuItemMetadataDTO> {
		return fetchMetadata(itemId);
	}

	public function createMetadata(itemId:Int, meta:MenuItemMetadataDTO):Int {
		var conn = db.acquire();
		try {
			var p = makeParams(["itemId", itemId, "keyName", meta.keyName, "value", meta.value]);
			conn.request(db.buildSql("INSERT INTO menu_item_metadata (item_id, key_name, value) VALUES (@itemId, @keyName, @value)", p));
			var id = conn.lastInsertId();
			db.release(conn);
			return id;
		} catch (e:Dynamic) {
			db.release(conn);
			throw e;
		}
	}

	public function updateMetadata(id:Int, meta:MenuItemMetadataDTO):Bool {
		var conn = db.acquire();
		try {
			var p = makeParams(["id", id, "keyName", meta.keyName, "value", meta.value]);
			conn.request(db.buildSql("UPDATE menu_item_metadata SET key_name = @keyName, value = @value WHERE id = @id", p));
			db.release(conn);
			return true;
		} catch (e:Dynamic) {
			db.release(conn);
			throw e;
		}
	}

	public function deleteMetadata(id:Int):Bool {
		var conn = db.acquire();
		try {
			conn.request('DELETE FROM menu_item_metadata WHERE id = $id');
			db.release(conn);
			return true;
		} catch (e:Dynamic) {
			db.release(conn);
			throw e;
		}
	}

	// ==================== Internal Eager-Loading Helpers ====================

	private function fetchSections(menuId:Int):Array<MenuSectionDTO> {
		var conn = db.acquire();
		try {
			var rs = conn.request('SELECT * FROM menu_sections WHERE menu_id = $menuId ORDER BY sort_order ASC');
			var records:Array<Dynamic> = [];
			while (rs.hasNext())
				records.push(rs.next());
			db.release(conn);

			var result:Array<MenuSectionDTO> = [];
			for (rec in records)
				result.push(buildSection(rec));
			return result;
		} catch (e:Dynamic) {
			db.release(conn);
			throw e;
		}
	}

	private function fetchItems(sectionId:Int):Array<MenuItemDTO> {
		var conn = db.acquire();
		try {
			var rs = conn.request('SELECT * FROM menu_items WHERE section_id = $sectionId ORDER BY sort_order ASC');
			var records:Array<Dynamic> = [];
			while (rs.hasNext())
				records.push(rs.next());
			db.release(conn);

			var result:Array<MenuItemDTO> = [];
			for (rec in records)
				result.push(buildItem(rec));
			return result;
		} catch (e:Dynamic) {
			db.release(conn);
			throw e;
		}
	}

	private function fetchMetadata(itemId:Int):Array<MenuItemMetadataDTO> {
		var conn = db.acquire();
		try {
			var rs = conn.request('SELECT * FROM menu_item_metadata WHERE item_id = $itemId');
			var records:Array<Dynamic> = [];
			while (rs.hasNext())
				records.push(rs.next());
			db.release(conn);

			var result:Array<MenuItemMetadataDTO> = [];
			for (rec in records) {
				result.push({
					id: Std.int(rec.id),
					itemId: Std.int(rec.item_id),
					keyName: Std.string(rec.key_name),
					value: Std.string(rec.value)
				});
			}
			return result;
		} catch (e:Dynamic) {
			db.release(conn);
			throw e;
		}
	}

	// ==================== Record Builders ====================

	private function buildMenu(rec:Dynamic):MenuDTO {
		return {
			id: Std.int(rec.id),
			name: Std.string(rec.name),
			slug: Std.string(rec.slug),
			icon: Std.string(rec.icon),
			sortOrder: Std.int(rec.sort_order),
			enabled: rec.enabled == 1,
			sections: fetchSections(Std.int(rec.id)),
			visibilityConfig: null
		};
	}

	private function buildSection(rec:Dynamic):MenuSectionDTO {
		return {
			id: Std.int(rec.id),
			menuId: Std.int(rec.menu_id),
			title: Std.string(rec.title),
			layoutType: Std.string(rec.layout_type),
			sortOrder: Std.int(rec.sort_order),
			enabled: rec.enabled == 1,
			items: fetchItems(Std.int(rec.id))
		};
	}

	private function buildItem(rec:Dynamic):MenuItemDTO {
		return {
			id: Std.int(rec.id),
			sectionId: Std.int(rec.section_id),
			label: Std.string(rec.label),
			description: Std.string(rec.description),
			url: Std.string(rec.url),
			icon: Std.string(rec.icon),
			itemType: Std.string(rec.item_type),
			customComponent: Std.string(rec.custom_component),
			sortOrder: Std.int(rec.sort_order),
			enabled: rec.enabled == 1,
			metadata: fetchMetadata(Std.int(rec.id)),
			visibilityConfig: null
		};
	}
}
