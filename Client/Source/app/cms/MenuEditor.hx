package app.cms;

import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.containers.VBox;
import haxe.ui.containers.HBox;
import haxe.ui.components.Button;
import haxe.ui.components.Label;
import haxe.ui.components.TextField;
import sidewinder.core.DI;
import app.cms.ICmsManager;
import app.models.MegaMenuModels;

/** Menu editor dialog for editing a single menu */
class MenuEditor extends Dialog {
	var cmsManager:ICmsManager;
	var menuId:Int = 0;
	var menu:MenuDTO;

	// UI
	var titleLabel:Label;
	var nameField:TextField;
	var slugField:TextField;
	var enabledLabel:Label;
	var saveBtn:Button;
	var closeBtn:Button;

	public var onSaved:MenuDTO->Void; // callback when saved

	public function new() {
		super();
		this.cmsManager = DI.get(ICmsManager);
		this.title = "Menu Editor";
		this.width = 600;
		this.height = 400;
		this.destroyOnClose = true;
	}

	override public function onReady():Void {
		super.onReady();
		buildUI();
		if (menuId > 0)
			loadMenu(menuId);
	}

	function buildUI():Void {
		var root = new VBox();
		root.percentWidth = 100;
		root.percentHeight = 100;

		titleLabel = new Label();
		titleLabel.text = "Editing Menu";
		root.addComponent(titleLabel);

		var nameRow = new HBox();
		var nameLbl = new Label();
		nameLbl.text = "Name:";
		nameLbl.width = 100;
		nameRow.addComponent(nameLbl);
		nameField = new TextField();
		nameField.percentWidth = 100;
		nameRow.addComponent(nameField);
		root.addComponent(nameRow);

		var slugRow = new HBox();
		var slugLbl = new Label();
		slugLbl.text = "Slug:";
		slugLbl.width = 100;
		slugRow.addComponent(slugLbl);
		slugField = new TextField();
		slugField.percentWidth = 100;
		slugRow.addComponent(slugField);
		root.addComponent(slugRow);

		enabledLabel = new Label();
		enabledLabel.text = "Enabled:";
		root.addComponent(enabledLabel);

		var btnRow = new HBox();
		btnRow.percentWidth = 100;
		var spacer = new haxe.ui.components.Spacer();
		spacer.percentWidth = 100;
		btnRow.addComponent(spacer);
		saveBtn = new Button();
		saveBtn.text = "Save";
		saveBtn.onClick = function(_) save();
		btnRow.addComponent(saveBtn);
		closeBtn = new Button();
		closeBtn.text = "Close";
		closeBtn.onClick = function(_) this.hideDialog(null);
		btnRow.addComponent(closeBtn);
		root.addComponent(btnRow);

		this.addComponent(root);
	}

	public function loadMenu(id:Int):Void {
		this.menuId = id;
		cmsManager.getMenuAsync(id, function(m:MenuDTO) {
			menu = m;
			titleLabel.text = 'Editing: ' + (menu != null ? menu.name : '#' + id);
			if (menu != null) {
				nameField.text = menu.name;
				slugField.text = menu.slug;
				enabledLabel.text = 'Enabled: ' + (menu.enabled ? 'Yes' : 'No');
			}
		}, function(err:Dynamic) {
			titleLabel.text = 'Failed to load menu #' + id;
		});
	}

	function save():Void {
		if (menu == null)
			return;
		menu.name = nameField.text;
		menu.slug = slugField.text;
		// Persist changes via service
		untyped app.services.AsyncServiceRegistry.instance.megaMenu.updateMenuAsync(menu.id, menu, function(success:Bool) {
			if (success) {
				if (onSaved != null)
					onSaved(menu);
				this.hideDialog(null);
			} else {
				// Show basic error; could use Notifications
			}
		}, function(err:Dynamic) {
			// Show basic error
		});
	}
}
