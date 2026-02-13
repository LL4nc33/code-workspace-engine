# API Documentation: {{PROJECT_NAME}}

## Base URL

```
{{API_BASE_URL}}
```

## Authentication

[Authentication method and usage]

## Endpoints

### Resource A

#### List

```
GET /api/resource-a
```

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| page | integer | No | Page number (default: 1) |
| limit | integer | No | Items per page (default: 20) |

**Response:** `200 OK`

```json
{
  "data": [],
  "meta": { "page": 1, "total": 0 }
}
```

#### Create

```
POST /api/resource-a
```

**Body:**

```json
{
  "name": "string",
  "description": "string"
}
```

**Response:** `201 Created`

## Error Codes

| Code | Meaning |
|------|---------|
| 400 | Bad Request — invalid input |
| 401 | Unauthorized — missing or invalid auth |
| 403 | Forbidden — insufficient permissions |
| 404 | Not Found — resource doesn't exist |
| 500 | Internal Server Error |
