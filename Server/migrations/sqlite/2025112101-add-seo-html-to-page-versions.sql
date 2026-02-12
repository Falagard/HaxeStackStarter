-- Migration: Add seo_html to page_versions for cached SEO HTML

ALTER TABLE page_versions ADD COLUMN seo_html TEXT;
