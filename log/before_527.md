### 5/15

##### s3

1. s3
2. s3 policy
3. iam policy document
4. s3 public access block
5. s3 OwnerShip
   - BucketOwnerPreferred: Bucket Owner owns all objects if no acl is used
   - BucketOwnerEnforced: ACL is always ignored, bucket owner always owns everything
   - ObjectWriter: Object writer owns everything

Questions:

1. when to use acl and when not to? is it for log services?
   - for cloudfront write -> in which step does the frontend directly upload stuff to s3?
   - could use OAC instead
2. presigned_url not used in app??
3. how does django native FileField and ImageField deal with it?

---

### 5/18

#### Actions

1. setup a VPC with one public subnet and one private subnet
2. setup s3
3. setup a ecs
4. set up a ElastiCache

---

### 5/20

#### Apply

N/A

#### Code

1. Setup RDS for PG
2. update private and public subnet to span across multiple az

#### Questions

##### RDS

- Amazon RDS Performance Insights for performance check
- Aurora PostgreSQL: a cloud based DB solution, re-architected for cloud with decoupled compute and storage. While rds for PG ties storage with the instance. Though one can tie a EBS with the instance to extend the storage.
- allocated storage is the initial storage in GB. could scale up but not down later
- storage_type: the type of EBS volume
- requires at least two az for possible failover

##### Security Group

- Security groups are VPC-scoped
- protocol == -1 meant all protocol, tcp, udp, icmp and all

#### Todo

1. RDS (Continue)
   - Monitoring
   - Credentials in Secret Manager
   - Apply
2. ALB (New)

### 5/25

#### Apply

N/A

#### Code

1. setup elasticache security group for future computing instance to access

#### Questions

##### ECS

- why use network configuration to set up security group in aws_ecs_service?
  => network_mode = "awsvpc", which is required for Fargate, means every task gets its own ENI(Elastic Network Interface). That's why we define the security group for each tasks independently thru their network config.

##### Elasticache

- in security group of ingress/egress, from_port and to_port defines the range of port allowed

#### Todo

1. RDS (Continue)
   - Monitoring
   - Credentials in Secret Manager
   - Apply
2. ALB (New)

### 5/26

#### Apply

#### Code

1. service security group
2.

#### Questions

##### DB in general

- schemas vs dbs

##### Security Group, Secrets Manger

- if ingress is not defined => no inbound access at all
- how does github CD fetch secretsmanager? => when using codebuild, we simply set the IAM role of codebuild, and set the rules for it in policy_document

##### RDS

- with random_password, why special=True, what does this do? -> tp include special characters
