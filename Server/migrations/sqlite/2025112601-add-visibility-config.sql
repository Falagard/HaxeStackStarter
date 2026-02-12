-- Migration: Add visibilityConfig to CMS tables
-- Date: 20251126

-- Add to pages
aLTER TABLE pages
ADD visibilityConfig TEXT NOT NULL DEFAULT '{"visibilityMode":"Public","groupIds":[]}';

-- Add to page_components
ALTER TABLE page_components
ADD visibilityConfig TEXT NOT NULL DEFAULT '{"visibilityMode":"Public","groupIds":[]}';

-- Add to menus
ALTER TABLE menus
ADD visibilityConfig TEXT NOT NULL DEFAULT '{"visibilityMode":"Public","groupIds":[]}';

-- Add to menu_items
ALTER TABLE menu_items
ADD visibilityConfig TEXT NOT NULL DEFAULT '{"visibilityMode":"Public","groupIds":[]}';
