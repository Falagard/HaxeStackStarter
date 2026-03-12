package app.cms.components;

import haxe.ui.core.Component;
import haxe.ui.containers.VBox;
import haxe.ui.containers.HBox;
import haxe.ui.components.Label;
import haxe.ui.containers.TableView;
import haxe.ui.components.DropDown;
import haxe.ui.data.ArrayDataSource;
import app.models.MegaMenuModels;
import app.services.IMegaMenuService;
import app.cms.ICmsManager;
import sidewinder.core.DI;

/** Menu list component for displaying a selected menu on a page */
class MenuListComponent extends BaseComponent {
	var cmsManager:ICmsManager;
	var tableDataSource:ArrayDataSource<Dynamic>;

	/** Callback when user wants to edit a menu */
	public var onEditMenu:Int->Void = null;

	public function new(?id:String) {
		super(id, "menulist");
		if (_props.menuId == null)
			_props.menuId = 0;
		if (_props.showTitle == null)
			_props.showTitle = true;
		if (_props.layout == null)
			_props.layout = "vertical"; // vertical, horizontal, grid
		this.cmsManager = DI.get(ICmsManager);
	}

	override public function render():Component {
		var root = new VBox();
		root.percentWidth = 100;

		// Top label
		var header = new Label();
		header.text = "Menus";
		root.addComponent(header);

		// Table of menus
		var table = new TableView();
		table.addColumn("ID").width = 80;
		table.addColumn("Slug").width = 120;
		table.addColumn("Name").width = 200;
		table.addColumn("Enabled").width = 100;
		tableDataSource = new ArrayDataSource<Dynamic>();
		table.dataSource = tableDataSource;
		table.onClick = function(_) {
			var item = table.selectedItem;
			if (item != null && item.menuId != null) {
				_props.menuId = item.menuId;
				if (onEditMenu != null)
					onEditMenu(item.menuId);
			}
		};
		root.addComponent(table);

		// Load menus into table
		cmsManager.listMenusAsync(function(menus:Array<MenuDTO>) {
			tableDataSource.clear();
			for (m in menus) {
				var row:Dynamic = {
					ID: m.id,
					Slug: m.slug,
					Name: m.name,
					Enabled: m.enabled ? "Yes" : "No",
					menuId: m.id
				};
				tableDataSource.add(row);
			}
		}, function(err:Dynamic) {
			var errorLabel = new Label();
			errorLabel.text = "Error listing menus: " + Std.string(err);
			root.addComponent(errorLabel);
		});

		return root;
	}

	function renderMenu(container:VBox, menu:MenuDTO):Void {
		// Show menu title if enabled
		if (_props.showTitle == true && menu.name != null && menu.name != "") {
			var titleLabel = new Label();
			titleLabel.text = menu.name;
			titleLabel.styleNames = "menu-title";
			titleLabel.percentWidth = 100;
			container.addComponent(titleLabel);
		}

		// Render sections
		if (menu.sections != null && menu.sections.length > 0) {
			for (section in menu.sections) {
				if (section.enabled) {
					renderSection(container, section);
				}
			}
		} else {
			var emptyLabel = new Label();
			emptyLabel.text = "This menu has no sections.";
			container.addComponent(emptyLabel);
		}
	}

	function renderSection(container:VBox, section:MenuSectionDTO):Void {
		var sectionBox = new VBox();
		sectionBox.percentWidth = 100;
		sectionBox.styleNames = "menu-section";

		// Section title
		if (section.title != null && section.title != "") {
			var sectionTitle = new Label();
			sectionTitle.text = section.title;
			sectionTitle.styleNames = "menu-section-title";
			sectionBox.addComponent(sectionTitle);
		}

		// Render items based on layout
		if (section.items != null && section.items.length > 0) {
			var layout = Std.string(_props.layout);
			switch (layout) {
				case "horizontal":
					renderItemsHorizontal(sectionBox, section.items);
				case "grid":
					renderItemsGrid(sectionBox, section.items);
				default: // vertical
					renderItemsVertical(sectionBox, section.items);
			}
		}

		container.addComponent(sectionBox);
	}

	function renderItemsVertical(container:VBox, items:Array<MenuItemDTO>):Void {
		for (item in items) {
			if (item.enabled) {
				var itemBox = new VBox();
				itemBox.percentWidth = 100;
				itemBox.styleNames = "menu-item";

				var label = new Label();
				label.text = item.label;
				if (item.url != null && item.url != "") {
					label.styleNames = "menu-item-link";
					// TODO: Add click handler to navigate to URL
				}
				itemBox.addComponent(label);

				if (item.description != null && item.description != "") {
					var desc = new Label();
					desc.text = item.description;
					desc.styleNames = "menu-item-description";
					itemBox.addComponent(desc);
				}

				container.addComponent(itemBox);
			}
		}
	}

	function renderItemsHorizontal(container:VBox, items:Array<MenuItemDTO>):Void {
		var hbox = new HBox();
		hbox.percentWidth = 100;

		for (item in items) {
			if (item.enabled) {
				var itemBox = new VBox();
				itemBox.styleNames = "menu-item";

				var label = new Label();
				label.text = item.label;
				if (item.url != null && item.url != "") {
					label.styleNames = "menu-item-link";
				}
				itemBox.addComponent(label);

				hbox.addComponent(itemBox);
			}
		}

		container.addComponent(hbox);
	}

	function renderItemsGrid(container:VBox, items:Array<MenuItemDTO>):Void {
		// Simple grid layout using rows of HBox
		var currentRow:HBox = null;
		var itemsPerRow = 3; // Configurable
		var itemCount = 0;

		for (item in items) {
			if (item.enabled) {
				if (itemCount % itemsPerRow == 0) {
					currentRow = new HBox();
					currentRow.percentWidth = 100;
					container.addComponent(currentRow);
				}

				var itemBox = new VBox();
				itemBox.styleNames = "menu-item menu-item-grid";
				itemBox.percentWidth = 100 / itemsPerRow;

				var label = new Label();
				label.text = item.label;
				if (item.url != null && item.url != "") {
					label.styleNames = "menu-item-link";
				}
				itemBox.addComponent(label);

				if (item.description != null && item.description != "") {
					var desc = new Label();
					desc.text = item.description;
					desc.styleNames = "menu-item-description";
					itemBox.addComponent(desc);
				}

				currentRow.addComponent(itemBox);
				itemCount++;
			}
		}
	}
}
