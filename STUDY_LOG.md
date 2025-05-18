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

### 5/18

1. setup a VPC with one public subnet and one private subnet
2. setup s3

##### RDS

##### ElastiCache
