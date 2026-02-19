package app.views;

import haxe.ui.containers.SideBar;

@:build(haxe.ui.ComponentBuilder.build("Assets/sidebar-view.xml"))
class SidebarView extends SideBar {
	public function new() {
		super();
		this.position = "left";
		this.method = "float";
		this.width = 250;
		this.percentHeight = 100;
	}

	@:bind(closeSideBar, haxe.ui.events.MouseEvent.CLICK)
	private function onClose(_) {
		this.hide();
	}
}
