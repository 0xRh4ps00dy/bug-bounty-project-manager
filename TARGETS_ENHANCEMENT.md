# Targets Enhancement - URL, IP, and Domain Support

## Overview

The targets feature has been enhanced to support multiple types of targets beyond just URLs:

- **URL**: Full URLs (e.g., `https://example.com`, `https://api.example.com/endpoint`)
- **IP**: IPv4 and IPv6 addresses (e.g., `192.168.1.1`, `2001:0db8:85a3::8a2e:0370:7334`)
- **Domain**: Domain names (e.g., `example.com`, `subdomain.example.co.uk`)

## Changes Made

### Database Schema

1. **Column Rename**: `url` → `target`
   - More generic name to accommodate URLs, IPs, and domains
   - Column type remains `VARCHAR(500)`

2. **New Column**: `target_type`
   - Type: `ENUM('url', 'ip', 'domain')`
   - Default: `'url'`
   - Allows filtering and validation by target type

### Backend (PHP)

**TargetController.php** enhancements:
- Added `validateTarget(string $target, string $type): bool` method
- Added `isValidUrl(string $url): bool` validation method
- Added `isValidIp(string $ip): bool` validation method (IPv4 & IPv6)
- Added `isValidDomain(string $domain): bool` validation method
- Updated `store()` method to accept `target` and `target_type` parameters
- Updated `update()` method with validation for all target types

### Frontend (Views)

**targets/index.php** changes:
- Added "Target Type" column to the targets table
- Updated form modal with dropdown selector for target type
- Added dynamic placeholder updates based on selected type
- Conditional link rendering (URLs are clickable links, IPs/Domains are plain text)
- Different badge colors for each target type (primary for URL, info for IP, secondary for Domain)

**targets/show.php** changes:
- Added "Type" information display
- Updated grid layout to accommodate target type
- Updated breadcrumb to show target value instead of URL

### API Documentation

Updated `API_DOCUMENTATION.md`:
- Changed all `url` references to `target`
- Added `target_type` to response examples
- Updated POST request examples for all three types
- Updated cURL examples with all target type examples
- Updated Python (requests) examples

## Migration Guide

### For New Installations

The new schema will be created automatically from `mysql/init.sql` with:
- `target` column (renamed from `url`)
- `target_type` column with default value `'url'`

### For Existing Installations

If you have an existing database, run the migration:

```sql
-- Add the target_type column
ALTER TABLE targets 
ADD COLUMN target_type ENUM('url', 'ip', 'domain') DEFAULT 'url' AFTER target;

-- If you want to rename the url column to target:
-- (Only if you haven't already renamed it)
-- ALTER TABLE targets CHANGE COLUMN url target VARCHAR(500);

-- The default 'url' type will be assigned to all existing targets
```

Or use the provided migration file:
```bash
mysql -u user -p database < mysql/migrations/001_add_target_type.sql
```

## API Changes

### Creating Targets

**Before:**
```json
{
  "project_id": 1,
  "url": "https://example.com",
  "description": "Example target"
}
```

**After:**
```json
{
  "project_id": 1,
  "target": "https://example.com",
  "target_type": "url",
  "description": "Example target"
}
```

### Target Type Examples

**URL Example:**
```json
{
  "project_id": 1,
  "target": "https://api.example.com/v1",
  "target_type": "url",
  "description": "API Endpoint"
}
```

**IP Example:**
```json
{
  "project_id": 1,
  "target": "192.168.1.100",
  "target_type": "ip",
  "description": "Internal Server"
}
```

**Domain Example:**
```json
{
  "project_id": 1,
  "target": "example.com",
  "target_type": "domain",
  "description": "Root Domain"
}
```

## Validation Rules

### URL Validation
- Must be a valid URL format
- Supports http:// and https://
- Can include paths and query parameters

### IP Validation
- Supports both IPv4 and IPv6 formats
- IPv4: `192.168.1.1`
- IPv6: `2001:0db8:85a3::8a2e:0370:7334`

### Domain Validation
- Must follow domain name rules
- Each label (between dots) must be 1-63 characters
- Labels can contain letters, numbers, and hyphens
- Must have at least one dot and a valid TLD
- Examples: `example.com`, `sub.example.co.uk`, `test-domain.org`

## Testing

Test the functionality with different target types:

**cURL - Create URL Target:**
```bash
curl -X POST http://localhost/api/targets \
  -H "Content-Type: application/json" \
  -d '{
    "project_id": 1,
    "target": "https://example.com",
    "target_type": "url",
    "description": "Main website"
  }'
```

**cURL - Create IP Target:**
```bash
curl -X POST http://localhost/api/targets \
  -H "Content-Type: application/json" \
  -d '{
    "project_id": 1,
    "target": "192.168.1.100",
    "target_type": "ip",
    "description": "Internal server"
  }'
```

**cURL - Create Domain Target:**
```bash
curl -X POST http://localhost/api/targets \
  -H "Content-Type: application/json" \
  -d '{
    "project_id": 1,
    "target": "example.com",
    "target_type": "domain",
    "description": "Root domain"
  }'
```

## Files Modified

- `mysql/init.sql` - Updated schema
- `mysql/migrations/001_add_target_type.sql` - Migration file (new)
- `app/Controllers/TargetController.php` - Added validation methods
- `app/Views/targets/index.php` - Updated UI for target selection
- `app/Views/targets/show.php` - Updated display layout
- `API_DOCUMENTATION.md` - Updated documentation

## Backward Compatibility

- Existing targets will automatically be assigned `target_type = 'url'`
- All URLs in existing data will continue to work
- The UI gracefully handles all three types

## Future Enhancements

Potential improvements:
- Filtering targets by type in the UI
- Bulk actions for targets of specific types
- Target type-specific test case checklists
- CIDR notation support for IP ranges
- Wildcard domain matching
