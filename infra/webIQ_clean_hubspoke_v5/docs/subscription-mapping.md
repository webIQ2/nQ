# Subscription and management-group defaults

These defaults are embedded in the one-click parameter files.

## Subscriptions
- `webIQ Infrastructure` - `7426560d-ace3-4e95-9df4-69985fb9d8cc`
- `netIQ` - `ff60f646-9751-4074-9f58-9fc310105c4c`
- `Gi (Government Issue)` - `1011dd77-657c-4c57-931b-0b77b92e7378`
- `webIQ Management` - `604ca1f3-dab9-4da5-ac37-e8effa89c826`
- `webIQ Audit` - `ebdb6704-b8fb-4908-97e6-5bbe9cc59758`
- `webIQ Production` - `5c351373-7e27-43cf-86e0-bceae63ee3c6`

## Management groups
- `Networking`
- `Commercial`
- `Government`
- `Management`
- `IAM`
- `Production`

## Deployment defaults used in this package
- Hub resources deploy into `webIQ Infrastructure`
- Commercial spoke resources deploy into `netIQ`
- Government spoke resources deploy into `Gi (Government Issue)`
