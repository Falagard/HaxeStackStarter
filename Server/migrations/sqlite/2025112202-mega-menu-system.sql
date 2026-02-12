-- Migration: Supabase-style Mega Menu System

CREATE TABLE IF NOT EXISTS menus (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    icon TEXT,
    sort_order INTEGER DEFAULT 0,
    enabled BOOLEAN DEFAULT 1
);

CREATE TABLE IF NOT EXISTS menu_sections (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    menu_id INTEGER NOT NULL,
    title TEXT,
    layout_type TEXT,
    sort_order INTEGER DEFAULT 0,
    enabled BOOLEAN DEFAULT 1,
    FOREIGN KEY (menu_id) REFERENCES menus(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS menu_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    section_id INTEGER NOT NULL,
    label TEXT,
    description TEXT,
    url TEXT,
    icon TEXT,
    item_type TEXT NOT NULL,
    custom_component TEXT,
    sort_order INTEGER DEFAULT 0,
    enabled BOOLEAN DEFAULT 1,
    FOREIGN KEY (section_id) REFERENCES menu_sections(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS menu_item_metadata (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    item_id INTEGER NOT NULL,
    key_name TEXT NOT NULL,
    value TEXT,
    FOREIGN KEY (item_id) REFERENCES menu_items(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_menus_slug ON menus(slug);
CREATE INDEX IF NOT EXISTS idx_menu_sections_menu_id ON menu_sections(menu_id);
CREATE INDEX IF NOT EXISTS idx_menu_items_section_id ON menu_items(section_id);
CREATE INDEX IF NOT EXISTS idx_menu_item_metadata_item_id ON menu_item_metadata(item_id);
