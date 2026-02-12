-- Migration: Add visibilityConfig to page_versions for visibility control
-- Date: 20251129

ALTER TABLE page_versions
ADD visibilityConfig TEXT NOT NULL DEFAULT '{"visibilityMode":"Public","groupIds":[]}';
