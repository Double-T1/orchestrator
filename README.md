Core Infra

1. VPC: Custom VPC with 1 public and 1 private subnets.
2. Internet Gateway: For public subnets.
3. NAT Gateway: For private subnets to access the internet securely (e.g., for updates).
4. Route Tables: Separate routes for public and private subnets.

5. security group
6. basic iam roles

---

Compute
ECS (Fargate) or EC2 Auto Scaling Group: For hosting your app containers or instances.

steps

1. ECR
2. ECS cluster
3. task definitions
4. ECS services
5. Security Group for
   - ALB (Allow HTTP/s)
   - tasks (Allow traffic from ALB or VPC)
6. IAM Roles
   - pull images from ecr
   - write logs to cloudwatch
   - ECS task execution role
   - Accessing S3 role

---

Storage

    S3: For file uploads, logs, static assets, and backups.

    EFS (optional): Shared filesystem across services.

    RDS or Aurora: For relational database (PostgreSQL/MySQL).

    ElastiCache (Redis): For caching.

---

Networking & Access

    ALB (Application Load Balancer): Public-facing entry point (HTTPS with ACM SSL cert).

    Private ALB/NLB (optional): For internal services.

    Security Groups: Strictly defined inbound/outbound rules.

    IAM Roles and Policies: Least-privilege access for services and users.

---

Security & Secrets

    ACM: Manage SSL/TLS certificates for HTTPS.

    Secrets Manager or SSM Parameter Store: Store secrets and environment variables.

    CloudTrail: Audit logging.

    GuardDuty (optional): Threat detection.

---

CI/CD & Observability

    CodePipeline + CodeBuild or GitHub Actions with OIDC: CI/CD pipeline.

    CloudWatch: Logs, metrics, alarms.

    X-Ray (optional): Distributed tracing.

    Sentry/Datadog/New Relic (external): Enhanced monitoring.

---

Notifications & Ops

    SNS: Alerts (e.g., deployment or failure).

    Discord integration via Lambda or webhook.

---

Environment Setup

Use a consistent environment strategy:

    dev, stg, prod (each isolated in VPC, optionally separate AWS accounts).

    Reuse same module pattern in Terraform for repeatability.
