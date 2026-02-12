-- Migration: Add menu_item_components table for menu item component management

CREATE TABLE IF NOT EXISTS menu_item_components (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    menu_item_id INTEGER NOT NULL,
    sort_order INTEGER NOT NULL,
    type TEXT NOT NULL,
    data_json TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (menu_item_id) REFERENCES menu_items(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_menu_item_component_item_id ON menu_item_components(menu_item_id);
