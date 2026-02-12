-- Menu system for hierarchical navigation

CREATE TABLE IF NOT EXISTS menus (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS menu_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    menu_id INTEGER NOT NULL,
    parent_id INTEGER,
    title TEXT NOT NULL,
    page_id INTEGER,
    external_url TEXT,
    sort_order INTEGER DEFAULT 0,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (menu_id) REFERENCES menus(id) ON DELETE CASCADE,
    FOREIGN KEY (parent_id) REFERENCES menu_items(id) ON DELETE CASCADE,
    FOREIGN KEY (page_id) REFERENCES pages(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_menu_items_menu_id ON menu_items(menu_id);
CREATE INDEX IF NOT EXISTS idx_menu_items_parent_id ON menu_items(parent_id);
CREATE INDEX IF NOT EXISTS idx_menu_items_page_id ON menu_items(page_id);