-- Migration: Add slug to page_versions for versioned slugs
ALTER TABLE page_versions ADD COLUMN slug VARCHAR(255);