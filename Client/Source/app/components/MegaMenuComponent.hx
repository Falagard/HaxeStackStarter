package app.components;

import haxe.ui.containers.VBox;
import haxe.ui.components.Label;
import haxe.ui.components.Button;
import haxe.ui.containers.HBox;
import app.models.MegaMenuModels;
import app.services.AsyncServiceRegistry;

class MegaMenuComponent extends VBox {
	public function new() {
		super();
		this.percentWidth = 100;
		this.addClass("mega-menu-component");
	}

	public function loadAllMenus():Void {
		var service = AsyncServiceRegistry.instance.megaMenu;

		untyped service.listMenusAsync(function(menus:Array<MenuDTO>) {
			renderMenus(menus);
		}, function(error:Dynamic) {
			trace("Error loading menus: " + error);
			var errorLabel = new Label();
			errorLabel.text = "Error loading menus.";
			this.addComponent(errorLabel);
		});
	}

	private function renderMenus(menus:Array<MenuDTO>):Void {
		this.removeAllComponents();

		if (menus == null || menus.length == 0) {
			var label = new Label();
			label.text = "No menus found.";
			this.addComponent(label);
			return;
		}

		for (menu in menus) {
			renderMenuAccordion(menu);
		}
	}

	private function renderMenuAccordion(menu:MenuDTO):Void {
		var menuContainer = new VBox();
		menuContainer.percentWidth = 100;
		menuContainer.addClass("menu-accordion-item");

		// Header / Toggle
		var header = new Button();
		header.text = menu.name;
		header.percentWidth = 100;
		header.addClass("menu-accordion-header");
		header.toggle = true; // Make it toggleable if supported, or just use click

		var content = new VBox();
		content.percentWidth = 100;
		content.addClass("menu-accordion-content");
		content.hidden = true; // Start hidden

		// Toggle logic
		header.onClick = function(e) {
			content.hidden = !content.hidden;
		};

		menuContainer.addComponent(header);
		menuContainer.addComponent(content);
		this.addComponent(menuContainer);

		// Populate content
		if (menu.sections != null) {
			for (section in menu.sections) {
				renderSection(section, content);
			}
		}
	}

	private function renderSection(section:MenuSectionDTO, parent:VBox):Void {
		var sectionContainer = new VBox();
		sectionContainer.percentWidth = 100;
		sectionContainer.addClass("menu-section");

		if (section.title != null && section.title.length > 0) {
			var title = new Label();
			title.text = section.title;
			title.addClass("menu-section-title");
			sectionContainer.addComponent(title);
		}

		// Render items
		if (section.items != null) {
			var itemsContainer = new VBox();
			itemsContainer.percentWidth = 100;
			itemsContainer.addClass("menu-items-container");

			for (item in section.items) {
				var itemComp = renderItem(item);
				itemsContainer.addComponent(itemComp);
			}
			sectionContainer.addComponent(itemsContainer);
		}

		parent.addComponent(sectionContainer);
	}

	private function renderItem(item:MenuItemDTO):haxe.ui.core.Component {
		var itemContainer = new HBox();
		itemContainer.addClass("menu-item");
		itemContainer.percentWidth = 100;

		var link = new Button();
		link.text = item.label;
		link.percentWidth = 100;
		link.styleNames = "menu-item-link"; // Add a style name for customization

		if (item.url != null) {
			link.onClick = function(e) {
				trace("Navigate to: " + item.url);
				var dest = item.url;
				var isExternal = dest.indexOf("http") == 0;

				if (!isExternal && app.state.PageNavigator.instance != null) {
					// Remove hash if present for internal navigation
					if (dest.indexOf("#") == 0) {
						dest = dest.substr(1);
					}

					var parts = dest.split(':');
					var pageId = parts[0];
					var anchor = parts.length > 1 ? parts[1] : null;

					app.state.PageNavigator.instance.navigate(pageId, anchor);
				} else {
					#if js
					js.Browser.window.location.href = item.url;
					#end
				}
			};
		}

		itemContainer.addComponent(link);
		return itemContainer;
	}
}
