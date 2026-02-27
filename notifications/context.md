# Notifications — Context

## Purpose

Notifications inform customers, drivers, and recipients about state changes in the system. Each status change should trigger appropriate notifications. The notification system supports multiple channels: in-app, email, SMS, webhook.

## Directory Structure

```
notifications/{notification_id}/
└── notification.json     # Notification data
```

## Schema: notification.json

| Field              | Type     | Required | Description                                  |
|--------------------|----------|----------|----------------------------------------------|
| id                 | string   | yes      | ULID                                         |
| type               | string   | yes      | shipment_status, route_status, alert, system  |
| channel            | string   | yes      | in_app, email, sms, webhook                  |
| recipient_type     | string   | yes      | customer, driver, recipient, admin            |
| recipient_id       | string   | yes      | ID of the recipient entity                   |
| title              | string   | yes      | Notification title                           |
| message            | string   | yes      | Notification body                            |
| entity_type        | string   | no       | Related entity type (shipment, route, etc.)  |
| entity_id          | string   | no       | Related entity ID                            |
| read               | boolean  | yes      | Whether notification has been read           |
| sent_at            | string   | no       | When notification was dispatched             |
| read_at            | string   | no       | When notification was read                   |
| created_at         | string   | yes      | ISO-8601 timestamp                           |

## Notification Triggers

| Event                        | Who gets notified      | Channel              |
|------------------------------|------------------------|----------------------|
| Shipment created             | Customer               | webhook, email       |
| Shipment picked up           | Customer, Recipient    | webhook, sms         |
| Shipment out for delivery    | Recipient              | sms, email           |
| Shipment delivered           | Customer, Recipient    | webhook, sms, email  |
| Shipment exception           | Customer, Recipient    | webhook, sms, email  |
| Route started                | Customer               | webhook              |
| Route completed              | Customer               | webhook              |
| Vehicle offline > 30 min     | Admin, Operator        | in_app, email        |
| Route > 3 exceptions         | Admin, Operator        | in_app, email        |
| ETA update                   | Recipient              | sms                  |

## CRUD Operations

- **Create**: Create `notifications/{id}/notification.json`
- **Read**: Read `notifications/{id}/notification.json`
- **Update**: Mark as read (set `read=true`, `read_at`)
- **Delete**: Remove after retention period (30 days for read notifications)
