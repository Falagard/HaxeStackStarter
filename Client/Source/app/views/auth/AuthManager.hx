package app.views.auth;

import haxe.ui.core.Component;
import app.state.AppState;
import app.views.auth.LoginDialog;
import app.views.auth.RegisterDialog;
import app.components.Notifications;
import app.models.AuthModels;

/**
 * Authentication manager - handles login/registration flow
 */
class AuthManager {
	var appState = AppState.instance;
	var parentComponent:Component;
	var loginDialog:LoginDialog;
	var registerDialog:RegisterDialog;

	public function new(parent:Component) {
		this.parentComponent = parent;
	}

	/**
	 * Check if user is authenticated, show login if not
	 * Calls callback after successful login or token verification
	 */
	public function checkAuthentication(?onAuthenticated:Void->Void):Bool {
		// Try to load stored token
		var storedToken = appState.loadStoredToken();
		if (storedToken != null) {
			// Verify the stored token is still valid
			verifyStoredToken(storedToken, onAuthenticated);
			// Assume valid for now, will update if verification fails
			return true;
		}
		// No stored token, show login
		showLogin(onAuthenticated);
		return false;
	}

	function verifyStoredToken(token:String, ?onAuthenticated:Void->Void):Void {
		// Inject token into CookieJar so the request includes it
		if (appState.asyncServices != null && appState.asyncServices.cookieJar != null) {
			var cookieStr = "session_token=" + token + "; Path=/; Max-Age=604800";
			appState.asyncServices.cookieJar.setCookie(cookieStr, appState.asyncServices.baseUrl);
		}

		// Call getCurrentUser to verify the token
		untyped appState.asyncServices.auth.getCurrentUserAsync(function(user:Null<UserPublic>) {
			if (user != null) {
				// Token is valid, update app state
				appState.setAuthentication(user, token);
				Notifications.show('Welcome back, ' + (user.username != null ? user.username : user.email), 'info');
				if (onAuthenticated != null)
					onAuthenticated();
			} else {
				// Token invalid, clear it and show login
				appState.clearAuthentication();
				showLogin(onAuthenticated);
			}
		}, function(err:Dynamic) {
			// Token verification failed, clear and show login
			trace('Token verification failed: ' + err);
			appState.clearAuthentication();
			showLogin(onAuthenticated);
		});
	}

	public function showLogin(?onLogin:Void->Void):Void {
		if (loginDialog != null)
			return; // already showing

		loginDialog = new LoginDialog();
		loginDialog.dialogParent = parentComponent;

		loginDialog.onLoginSuccess = function(user:UserPublic, token:String) {
			appState.setAuthentication(user, token);
			loginDialog = null;
			if (onLogin != null)
				onLogin();
		};

		loginDialog.onRegisterRequested = function() {
			// Close login and show registration
			var emailOrUsername = "";
			var password = "";
			if (loginDialog != null) {
				// Get current field values before closing
				emailOrUsername = loginDialog.getEmailOrUsername();
				password = loginDialog.getPassword();
				loginDialog.hideDialog("cancel");
				loginDialog = null;
			}
			showRegisterWithPrefill(emailOrUsername, password);
		};

		loginDialog.showDialog(true);
	}

	public function showRegister():Void {
		showRegisterWithPrefill("", "");
	}

	public function showRegisterWithPrefill(emailOrUsername:String, password:String):Void {
		if (registerDialog != null)
			return; // already showing

		registerDialog = new RegisterDialog();
		registerDialog.dialogParent = parentComponent;
		// Pre-fill fields if provided
		if (registerDialog.emailField != null)
			registerDialog.emailField.text = emailOrUsername;
		if (registerDialog.usernameField != null)
			registerDialog.usernameField.text = emailOrUsername;
		if (registerDialog.passwordField != null)
			registerDialog.passwordField.text = password;

		registerDialog.onRegisterSuccess = function(user:UserPublic) {
			registerDialog = null;
			// After registration, show login for user to sign in
			Notifications.show('Please sign in with your new account', 'info', 3000);
			haxe.ui.Toolkit.callLater(function() {
				showLogin();
			});
		};

		registerDialog.onBackToLogin = function() {
			// Close registration and show login
			if (registerDialog != null) {
				registerDialog.hideDialog("cancel");
				registerDialog = null;
			}
			showLogin();
		};

		registerDialog.showDialog(true);
	}

	public function logout():Void {
		untyped appState.asyncServices.auth.logoutAsync(function(success:Bool) {
			appState.clearAuthentication();
			Notifications.show('Signed out successfully', 'info');
			showLogin();
		}, function(err:Dynamic) {
			// Still clear local auth even if server call fails
			appState.clearAuthentication();
			Notifications.show('Signed out', 'info');
			showLogin();
		});
	}
}
