# API Documentation - Bug Bounty Project Manager

## Overview

The BBPM API provides RESTful endpoints for managing bug bounty projects, targets, categories, and checklist items. All API endpoints return JSON responses and support standard HTTP methods.

## Base URL

```
http://localhost/api
```

## Authentication

Currently, the API does not require authentication. This will be added in future versions.

## Content Type

All POST/PUT requests should include:
```
Content-Type: application/json
```

## Response Format

### Success Response
```json
{
  "success": true,
  "data": { ... },
  "message": "Operation successful"
}
```

### Error Response
```json
{
  "error": "Error message",
  "code": 400
}
```

## HTTP Status Codes

- `200 OK` - Request successful
- `201 Created` - Resource created successfully
- `400 Bad Request` - Invalid request data
- `404 Not Found` - Resource not found
- `500 Internal Server Error` - Server error

---

## Projects API

### List All Projects

**GET** `/api/projects`

Returns all projects with statistics.

**Response:**
```json
[
  {
    "id": 1,
    "name": "E-commerce Security",
    "description": "Testing e-commerce platform",
    "status": "active",
    "created_at": "2024-01-15 10:30:00",
    "updated_at": "2024-01-15 10:30:00",
    "target_count": 5,
    "avg_progress": 45.50
  }
]
```

### Get Project by ID

**GET** `/api/projects/{id}`

Returns a single project with all its targets.

**Parameters:**
- `id` (integer, required) - Project ID

**Response:**
```json
{
  "id": 1,
  "name": "E-commerce Security",
  "description": "Testing e-commerce platform",
  "status": "active",
  "created_at": "2024-01-15 10:30:00",
  "updated_at": "2024-01-15 10:30:00",
  "target_count": 5,
  "avg_progress": 45.50,
  "targets": [
    {
      "id": 1,
      "project_id": 1,
      "url": "https://shop.example.com",
      "description": "Main shop",
      "status": "active",
      "progress": 45.5,
      "created_at": "2024-01-15 11:00:00",
      "updated_at": "2024-01-15 15:30:00"
    }
  ]
}
```

### Create Project

**POST** `/api/projects`

Creates a new project.

**Request Body:**
```json
{
  "name": "New Project",
  "description": "Project description",
  "status": "active"
}
```

**Response:**
```json
{
  "success": true,
  "id": 5,
  "message": "Project created successfully"
}
```

### Update Project

**PUT** `/api/projects/{id}`

Updates an existing project.

**Parameters:**
- `id` (integer, required) - Project ID

**Request Body:**
```json
{
  "name": "Updated Project Name",
  "description": "Updated description",
  "status": "completed"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Project updated successfully"
}
```

### Delete Project

**DELETE** `/api/projects/{id}`

Deletes a project and all its targets.

**Parameters:**
- `id` (integer, required) - Project ID

**Response:**
```json
{
  "success": true,
  "message": "Project deleted successfully"
}
```

---

## Targets API

### List All Targets

**GET** `/api/targets`

Returns all targets.

**Response:**
```json
[
  {
    "id": 1,
    "project_id": 1,
    "url": "https://shop.example.com",
    "description": "Main shop",
    "status": "active",
    "progress": 45.5,
    "notes": "Aggregated notes from checklist items",
    "created_at": "2024-01-15 11:00:00",
    "updated_at": "2024-01-15 15:30:00"
  }
]
```

### Get Target by ID

**GET** `/api/targets/{id}`

Returns a single target with progress and checklist grouped by categories.

**Parameters:**
- `id` (integer, required) - Target ID

**Response:**
```json
{
  "target": {
    "id": 1,
    "project_id": 1,
    "project_name": "E-commerce Security",
    "url": "https://shop.example.com",
    "description": "Main shop",
    "status": "active",
    "progress": 45.50,
    "total_items": 367,
    "completed_items": 167,
    "notes": "Aggregated notes...",
    "created_at": "2024-01-15 11:00:00",
    "updated_at": "2024-01-15 15:30:00"
  },
  "checklist": {
    "1": {
      "category_name": "Reconnaissance",
      "items": [
        {
          "id": 1,
          "target_id": 1,
          "checklist_item_id": 1,
          "title": "Subdomain Enumeration",
          "description": "Find all subdomains",
          "is_checked": 1,
          "notes": "Found 15 subdomains using subfinder",
          "category_id": 1
        }
      ]
    }
  }
}
```

### Create Target

**POST** `/api/targets`

Creates a new target and automatically assigns all 367 checklist items.

**Request Body:**
```json
{
  "project_id": 1,
  "url": "https://api.example.com",
  "description": "API endpoints",
  "status": "active"
}
```

**Response:**
```json
{
  "success": true,
  "id": 10,
  "message": "Target created successfully"
}
```

### Update Target

**PUT** `/api/targets/{id}`

Updates an existing target.

**Parameters:**
- `id` (integer, required) - Target ID

**Request Body:**
```json
{
  "project_id": 1,
  "url": "https://api.example.com",
  "description": "Updated description",
  "status": "completed"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Target updated successfully"
}
```

### Delete Target

**DELETE** `/api/targets/{id}`

Deletes a target and all its checklist items.

**Parameters:**
- `id` (integer, required) - Target ID

**Response:**
```json
{
  "success": true,
  "message": "Target deleted successfully"
}
```

---

## Target Checklist API

### Toggle Checklist Item

**POST** `/api/targets/{targetId}/checklist/{itemId}/toggle`

Toggles the checked status of a checklist item.

**Parameters:**
- `targetId` (integer, required) - Target ID
- `itemId` (integer, required) - Checklist Item ID

**Request Body:**
```json
{
  "is_checked": 1
}
```

**Response:**
```json
{
  "success": true
}
```

### Update Checklist Item Notes

**POST** `/api/targets/{targetId}/checklist/{itemId}/notes`

Updates the notes for a checklist item. Notes are automatically aggregated to the target.

**Parameters:**
- `targetId` (integer, required) - Target ID
- `itemId` (integer, required) - Checklist Item ID

**Request Body:**
```json
{
  "notes": "Found XSS vulnerability in search parameter"
}
```

**Response:**
```json
{
  "success": true
}
```

---

## Categories API

### List All Categories

**GET** `/api/categories`

Returns all categories with item counts.

**Response:**
```json
[
  {
    "id": 1,
    "name": "Reconnaissance",
    "description": "Information gathering phase",
    "order_num": 1,
    "created_at": "2024-01-15 10:00:00",
    "item_count": 25
  }
]
```

### Create Category

**POST** `/api/categories`

Creates a new category.

**Request Body:**
```json
{
  "name": "Custom Category",
  "description": "Custom tests",
  "order_num": 31
}
```

**Response:**
```json
{
  "success": true,
  "id": 31
}
```

### Update Category

**PUT** `/api/categories/{id}`

Updates an existing category.

**Parameters:**
- `id` (integer, required) - Category ID

**Request Body:**
```json
{
  "name": "Updated Category",
  "description": "Updated description",
  "order_num": 32
}
```

**Response:**
```json
{
  "success": true
}
```

### Delete Category

**DELETE** `/api/categories/{id}`

Deletes a category.

**Parameters:**
- `id` (integer, required) - Category ID

**Response:**
```json
{
  "success": true
}
```

---

## Checklist Items API

### List All Checklist Items

**GET** `/api/checklist`

Returns all checklist items.

**Query Parameters:**
- `category_id` (integer, optional) - Filter by category

**Response:**
```json
[
  {
    "id": 1,
    "category_id": 1,
    "category_name": "Reconnaissance",
    "title": "Subdomain Enumeration",
    "description": "Find all subdomains using tools",
    "order_num": 1,
    "created_at": "2024-01-15 10:00:00"
  }
]
```

### Create Checklist Item

**POST** `/api/checklist`

Creates a new checklist item template.

**Request Body:**
```json
{
  "category_id": 1,
  "title": "New Test",
  "description": "Test description",
  "order_num": 100
}
```

**Response:**
```json
{
  "success": true,
  "id": 368
}
```

### Update Checklist Item

**PUT** `/api/checklist/{id}`

Updates an existing checklist item template.

**Parameters:**
- `id` (integer, required) - Checklist Item ID

**Request Body:**
```json
{
  "category_id": 1,
  "title": "Updated Test",
  "description": "Updated description",
  "order_num": 101
}
```

**Response:**
```json
{
  "success": true
}
```

### Delete Checklist Item

**DELETE** `/api/checklist/{id}`

Deletes a checklist item template.

**Parameters:**
- `id` (integer, required) - Checklist Item ID

**Response:**
```json
{
  "success": true
}
```

---

## Examples

### JavaScript (Fetch API)

```javascript
// Get all projects
const projects = await fetch('/api/projects')
  .then(res => res.json());

// Create a target
const newTarget = await fetch('/api/targets', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    project_id: 1,
    url: 'https://example.com',
    description: 'Test target',
    status: 'active'
  })
}).then(res => res.json());

// Toggle checklist item
await fetch('/api/targets/1/checklist/5/toggle', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    is_checked: 1
  })
});
```

### cURL

```bash
# Get all targets
curl http://localhost/api/targets

# Create project
curl -X POST http://localhost/api/projects \
  -H "Content-Type: application/json" \
  -d '{"name":"New Project","description":"Test","status":"active"}'

# Update target
curl -X PUT http://localhost/api/targets/1 \
  -H "Content-Type: application/json" \
  -d '{"url":"https://updated.com","description":"Updated","status":"active","project_id":1}'

# Delete project
curl -X DELETE http://localhost/api/projects/5
```

### Python (requests)

```python
import requests

BASE_URL = 'http://localhost/api'

# Get all projects
response = requests.get(f'{BASE_URL}/projects')
projects = response.json()

# Create target
data = {
    'project_id': 1,
    'url': 'https://example.com',
    'description': 'Test target',
    'status': 'active'
}
response = requests.post(f'{BASE_URL}/targets', json=data)
result = response.json()

# Toggle checklist
toggle_data = {'is_checked': 1}
requests.post(f'{BASE_URL}/targets/1/checklist/5/toggle', json=toggle_data)
```

---

## Rate Limiting

Currently, there is no rate limiting. This will be implemented in future versions.

## Versioning

API version: 1.0.0

## Support

For issues or questions, please open an issue on GitHub.
