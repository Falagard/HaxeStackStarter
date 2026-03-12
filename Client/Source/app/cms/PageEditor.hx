package app.cms;

import haxe.ui.containers.dialogs.Dialog;
import sidewinder.core.DI;
import haxe.ui.containers.VBox;
import haxe.ui.containers.HBox;
import haxe.ui.components.Button;
import haxe.ui.components.Label;
import haxe.ui.components.TextField;
import haxe.ui.components.DropDown;
import haxe.ui.components.Switch;
import app.cms.InspectorDialog;
import app.cms.ICmsManager;
import app.cms.ComponentFactory;
import app.cms.components.IPageComponent;
import app.cms.EditorComponent;
import app.models.CmsModels;
import app.models.VisibilityConfig;

/** Page editor dialog for editing pages with live preview */
@:build(haxe.ui.ComponentBuilder.build("Assets/page-editor.xml"))
class PageEditor extends Dialog {
	var showEditorButtons:Bool = true;
	var previewSwitch:Switch;

	function setShowEditorButtons(value:Bool):Void {
		showEditorButtons = value;
		hydrateEditor();
	}

	/** Move a component up or down in the list */
	public function moveComponentInEditor(editorComp:EditorComponent, direction:Int):Void {
		var idx = editorComponents.indexOf(editorComp);
		var newIdx = idx + direction;
		if (newIdx < 0 || newIdx >= editorComponents.length)
			return;
		editorComponents.remove(editorComp);
		editorComponents.insert(newIdx, editorComp);

		canvas.removeAllComponents(false);

		for (ec in editorComponents) {
			canvas.addComponent(ec.container);
		}
		// Optionally update sort order
		for (i in 0...editorComponents.length) {
			editorComponents[i].dto.sort = i;
		}
	}

	/** Add a new component to the canvas */
	function addNewComponent(type:String):Void {
		var comp = ComponentFactory.create(type);
		var dto:PageComponentDTO = {
			id: 0, // will be assigned by server
			type: comp.type,
			sort: editorComponents.length,
			data: comp.props,
			visibilityConfig: {visibilityMode: "public", groupIds: []}
		};
		var editorComp = new EditorComponent(dto, this);
		editorComponents.push(editorComp);
		canvas.addComponent(editorComp.container);
		selectComponent(editorComp);
	}

	/** Hydrate editor from current page data */
	function hydrateEditor():Void {
		editorComponents = [];
		canvas.removeAllComponents();
		if (currentPage != null && currentPage.components != null) {
			for (compDTO in currentPage.components) {
				var editorComp = new EditorComponent(compDTO, this, showEditorButtons);
				editorComponents.push(editorComp);
				canvas.addComponent(editorComp.container);
			}
		}
	}

	public var onSaved:PageVersionDTO->Void; // callback when page is saved

	// UI components from XML
	var componentList:VBox;
	var canvas:VBox;
	// var inspector:VBox; // removed, now using InspectorDialog
	var pageTitle:Label;
	var saveDraftBtn:Button;
	var publishBtn:Button;
	var editPageInfoBtn:Button; // new button for editing page info

	// Data
	var cmsManager:ICmsManager;
	var currentPage:PageVersionDTO;
	var pageSlug:String = ""; // store slug locally
	var editorComponents:Array<EditorComponent> = [];
	var selectedComponent:EditorComponent;

	public function new() {
		super();
		this.cmsManager = DI.get(ICmsManager);
		this.title = "Page Editor";
		this.destroyOnClose = true;
	}

	public override function onReady():Void {
		super.onReady();
		initializeUI();

		// Wire up preview switch
		if (previewSwitch != null) {
			previewSwitch.onChange = function(_) {
				setShowEditorButtons(!previewSwitch.selected);
			};
		}
	}

	function initializeUI():Void {
		// Setup component palette
		var types = ComponentFactory.getAvailableTypes();

		if (componentList != null) {
			componentList.removeAllComponents();
			for (type in types) {
				var btn = new Button();
				btn.text = "Add " + type;
				btn.percentWidth = 100;
				btn.userData = type;
				btn.onClick = function(_) addNewComponent(Std.string(btn.userData));
				componentList.addComponent(btn);
			}
		}

		// Wire up buttons
		if (saveDraftBtn != null)
			saveDraftBtn.onClick = function(_) saveDraft();
		if (publishBtn != null)
			publishBtn.onClick = function(_) publish();
		if (editPageInfoBtn != null) {
			var self = this;
			editPageInfoBtn.onClick = function(_) self.showEditPageInfoDialog();
		}
		if (previewSwitch != null) {
			previewSwitch.selected = false;
		}
	}

	public function showEditPageInfoDialog():Void {
		if (currentPage == null)
			return;
		var dlg = new PageInfoDialog(currentPage.title, pageSlug);
		dlg.onSave = function(newTitle:String, newSlug:String) {
			currentPage.title = newTitle;
			pageSlug = newSlug;
			if (pageTitle != null)
				pageTitle.text = newTitle;
			// Optionally, save immediately or require explicit saveDraft
		};
		dlg.onCancel = function() {};
		dlg.showDialog();
	}

	/** Load a page for editing */
	public function loadPage(pageId:Int):Void {
		cmsManager.getPage(pageId, function(response:GetPageResponse) {
			if (response.success && response.page != null) {
				currentPage = response.page;
				// Try to get slug from response.page if present
				if (Reflect.hasField(response.page, "slug")) {
					pageSlug = Reflect.field(response.page, "slug");
				} else {
					pageSlug = "";
				}
				hydrateEditor();
				pageTitle.text = currentPage.title;
			}
		});
	}

	/** Delete a component */
	public function selectComponent(editorComp:EditorComponent):Void {
		// Deselect previous
		if (selectedComponent != null) {
			selectedComponent.setSelected(false);
		}
		selectedComponent = editorComp;
		editorComp.setSelected(true);
		var inspectorDialog = new InspectorDialog();
		inspectorDialog.onClose = function() {
			// Optionally handle dialog close (e.g., refresh UI)
		};
		inspectorDialog.onDelete = function() {
			deleteComponent(editorComp);
		};
		inspectorDialog.showInspector(editorComp);
		inspectorDialog.showDialog();
	}

	function deleteComponent(editorComp:EditorComponent):Void {
		editorComponents.remove(editorComp);
		canvas.removeComponent(editorComp.container);
		// inspector.removeAllComponents(); // removed
		selectedComponent = null;
	}

	/** Save current state as draft */
	function saveDraft():Void {
		if (currentPage == null)
			return;

		// Build components array
		var components:Array<PageComponentDTO> = [];
		for (i in 0...editorComponents.length) {
			var ec = editorComponents[i];
			ec.dto.sort = i; // Update sort order
			components.push(ec.dto);
		}

		cmsManager.updatePage(currentPage.pageId, currentPage.title, currentPage.layout, components, pageSlug, currentPage.visibilityConfig,
			function(response:UpdatePageResponse) {
				if (response.success) {
					// Reload to get updated version info
					loadPage(currentPage.pageId);
					if (onSaved != null && currentPage != null)
						onSaved(currentPage);
				}
			});
	}

	/** Publish the current version */
	function publish():Void {
		if (currentPage == null)
			return;

		cmsManager.publishVersion(currentPage.pageId, currentPage.id, function(response:CreatePageResponse) {
			if (response.success) {
				// Optionally close or reload
			}
		});
	}
}
