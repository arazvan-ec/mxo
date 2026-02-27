# Audit — Context

## Purpose

Audit log records all significant operations for security, compliance, and debugging. Every entity change, login, and sensitive action is logged.

## Directory Structure

```
audit/{audit_id}/
└── audit.json            # Audit entry
```

## Schema: audit.json

| Field        | Type     | Required | Description                          |
|--------------|----------|----------|--------------------------------------|
| id           | string   | yes      | ULID                                 |
| action       | string   | yes      | create, update, delete, login, export|
| entity_type  | string   | yes      | Type of entity affected              |
| entity_id    | string   | yes      | ID of entity affected                |
| actor_type   | string   | yes      | user, agent, system                  |
| actor_id     | string   | yes      | Who performed the action             |
| changes      | object   | no       | Before/after values for updates      |
| ip_address   | string   | no       | Source IP                            |
| user_agent   | string   | no       | Source user-agent                    |
| timestamp    | string   | yes      | ISO-8601                             |
| notes        | string   | no       | Additional context                   |

### changes Object

```json
{
  "field_name": {
    "before": "old_value",
    "after": "new_value"
  }
}
```

## CRUD Operations

- **Create**: Create `audit/{id}/audit.json` (append-only by design)
- **Read**: Read individual entries or scan by entity/actor/date
- **Update**: Audit entries are immutable — never updated
- **Delete**: Only after legal retention period expires
