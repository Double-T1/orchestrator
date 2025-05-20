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

#### Actions

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
-

##### ElastiCache
