-- Migration: Add target_type column and rename url to target
-- This migration updates the targets table to support URLs, IPs, and domains

-- First, rename url column to target (if it exists)
ALTER TABLE targets CHANGE COLUMN url target VARCHAR(500);

-- Check if column doesn't exist before adding
ALTER TABLE targets 
ADD COLUMN target_type ENUM('url', 'ip', 'domain') DEFAULT 'url' AFTER target;

-- Update target_type based on existing target values
-- All existing targets are URLs (default behavior)
UPDATE targets SET target_type = 'url' WHERE target_type = 'url' OR target_type IS NULL;
