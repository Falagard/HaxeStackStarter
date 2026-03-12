package app.views;

import haxe.ui.containers.VBox;
import haxe.ui.components.Button;
import app.cms.megamenu.MegaMenuView;
import app.cms.megamenu.MegaMenuAdminDialog;
import app.views.SidebarView;
import haxe.ui.components.Button;
import haxe.ui.components.Label;
import app.state.AppState;
import app.components.Notifications;
import app.cms.ICmsManager;
import sidewinder.core.DI;
import app.models.CmsModels;
import app.cms.components.PageListComponent;
import app.cms.components.MenuListComponent;
import app.cms.MenuEditor;
import app.cms.PageEditor;
import app.views.auth.AuthManager;

@:build(haxe.ui.ComponentBuilder.build("Assets/main-view.xml"))
class MainView extends VBox {
	// var megaMenuView:MegaMenuView;
	var megaMenuAdminDialog:MegaMenuAdminDialog;
	var userLabel:Label; // from XML - displays current user
	var logoutBtn:Button; // from XML - logout button
	var cmsBtn:Button; // from XML - CMS button
	var contentPlaceholder:VBox; // from XML - main content area
	var mainLayout:haxe.ui.containers.HBox; // from XML

	var appState = AppState.instance;
	var asyncServices = AppState.instance.asyncServices;

	var cmsManager:ICmsManager;
	var currentPageList:PageListComponent;
	var currentEditor:PageEditor;

	var authManager:app.views.auth.AuthManager;

	// Page navigation
	var pageNavigator:app.state.PageNavigator;
	var pageRenderer:app.cms.PageRenderer;

	public function new() {
		super();

		var sidebar = new SidebarView();
		// this.addComponent(sidebar); // Add to root for floating behavior

		var menuButton = findComponent("menuButton", Button);
		if (menuButton != null) {
			menuButton.onClick = function(e) {
				if (sidebar.hidden) {
					sidebar.show();
				} else {
					sidebar.hide();
				}
			};
		}

		// Initialize CMS manager
		cmsManager = DI.get(ICmsManager);
		pageRenderer = new app.cms.PageRenderer();

		// Initialize PageNavigator
		pageNavigator = new app.state.PageNavigator(appState, cmsManager, pageRenderer);

		authManager = new app.views.auth.AuthManager(this);

		wireEvents();

		// Watch authentication state and update user display
		appState.currentUser.watch(function(user) {
			updateUserDisplay();
		});
		updateUserDisplay();

		// Listen for navigation events to update UI
		pageNavigator.onNavigate.push(function(response:GetPageResponse) {
			renderActivePage(response);
		});

		// Handle deep link from URL on app load, or navigate to default page 3
		if (!pageNavigator.handleInitialDeepLink()) {
			pageNavigator.navigate("1", null);
		}

		// --- MegaMenu Integration ---
		var menuComponent = new app.components.MegaMenuComponent();
		this.addComponent(menuComponent);
		// Load all menus
		menuComponent.loadAllMenus();
		// To show admin dialog, call megaMenuAdminDialog.showDialog() as needed
		// megaMenuAdminDialog = new MegaMenuAdminDialog(menuService);
	}

	/** Render the active page using PageNavigator */
	private function renderActivePage(response:GetPageResponse):Void {
		contentPlaceholder.removeAllComponents();
		if (response.success && response.page != null) {
			var rendered = pageRenderer.renderPage(response.page, pageNavigator.currentAnchor);
			contentPlaceholder.addComponent(rendered);
		} else {
			var errorLabel = new haxe.ui.components.Label();
			errorLabel.text = "Failed to load page.";
			contentPlaceholder.addComponent(errorLabel);
		}
	}

	private function updateUserDisplay():Void {
		if (userLabel != null) {
			var user = appState.currentUser.value;
			if (user != null) {
				var displayName = user.username != null ? user.username : user.email;
				userLabel.text = displayName;
			} else {
				userLabel.text = "";
			}
		}

		// Show/hide CMS button based on authentication
		if (cmsBtn != null) {
			var isAuthenticated = appState.isAuthenticated;
			cmsBtn.hidden = !isAuthenticated;
		}

		// Change logout button to login button if not authenticated
		if (logoutBtn != null) {
			if (!appState.isAuthenticated) {
				logoutBtn.text = "Login";
				logoutBtn.onClick = function(_) {
					authManager.showLogin(function() {
						updateUserDisplay(); // Show CMS button after login
					});
				};
			} else {
				logoutBtn.text = "Logout";
				logoutBtn.onClick = function(_) {
					handleLogout();
				};
			}
		}
	}

	private function wireEvents():Void {
		if (logoutBtn != null)
			logoutBtn.onClick = function(_) {
				handleLogout();
			};

		if (cmsBtn != null)
			cmsBtn.onClick = function(_) {
				showCMS();
			};
	}

	private function handleLogout():Void {
		untyped asyncServices.auth.logoutAsync(function(success:Bool) {
			appState.clearAuthentication();
			Notifications.show('Signed out successfully', 'info');
			#if js
			js.Browser.window.location.reload();
			#end
		}, function(err:Dynamic) {
			// Still clear local auth even if server call fails
			appState.clearAuthentication();
			Notifications.show('Signed out', 'info');
			#if js
			js.Browser.window.location.reload();
			#end
		});
	}

	/** Show the CMS page list with Back button */
	private var lastPage:String = null;

	private var lastAnchor:String = null;

	private function showCMS():Void {
		// Store current page and anchor before showing CMS
		lastPage = pageNavigator.currentPage;
		lastAnchor = pageNavigator.currentAnchor;

		// Clear current content
		contentPlaceholder.removeAllComponents();

		// Create Back button
		var backBtn = new Button();
		backBtn.text = "Back";
		backBtn.onClick = function(_) {
			if (lastPage != null) {
				pageNavigator.navigate(lastPage, lastAnchor);
			}
		};
		contentPlaceholder.addComponent(backBtn);

		// Create and show embeddable page list
		currentPageList = cast new PageListComponent();
		// Parent controls sizing; set percentWidth/percentHeight if desired:
		// currentPageList.percentWidth = 100;
		// currentPageList.percentHeight = 100;

		// Handle edit page request
		currentPageList.onEditPage = function(pageId:Int) {
			showPageEditor(pageId);
		};
		// Optionally handle view page event
		currentPageList.onViewPage = function(pageId:Int) {
			// Example: show a preview dialog or navigate
			Notifications.show('View page ' + pageId, 'info');
		};

		contentPlaceholder.addComponent(currentPageList.render());

		// Menus list and editor hook
		var menuList = new MenuListComponent();
		menuList.onEditMenu = function(menuId:Int) {
			showMenuEditor(menuId);
		};
		contentPlaceholder.addComponent(menuList.render());
	}

	/** Show the page editor */
	private function showPageEditor(pageId:Int):Void {
		currentEditor = new PageEditor();
		currentEditor.showDialog();
		currentEditor.loadPage(pageId); // Handle save callback to refresh list
		currentEditor.onSaved = function(_) {
			if (currentPageList != null) {
				currentPageList.loadPages();
			}
		};
	}

	/** Show the menu editor */
	private function showMenuEditor(menuId:Int):Void {
		var dlg = new MenuEditor();
		dlg.showDialog();
		dlg.loadMenu(menuId);
		dlg.onSaved = function(_) {
			// Optionally refresh menu list
		};
	}
}
