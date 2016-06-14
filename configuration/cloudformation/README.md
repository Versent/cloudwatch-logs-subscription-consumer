##ELK stack Introduction

The cloudformation template will create:

 - ELB;
 - Autoscalling group of 2 ELK servers;
 - Kinesis stream;
 - DynamoDB table (for the kinesis stream);
 - Log Destination;
 - Various security groups;
 - Alerts for health of the system;

 
##What's inside each of the ELK servers

1. It's based on RHEL72 SOE, which includes 
  - McAfee set of tools as per TU requirements; 
  - OS hardening;
  - aws-cli, cfn-init, awslogs, etc;
  
2. Elasticsearch 1.7.3 (latest 1.x relese);
3. Kibana 4.1.6 (Latest kibana 4 compatible with ES 1.x);
4. Nginx, for htpassword support/reverseproxy;
4. **CloudWatch Log Subscription Consumer** https://github.com/awslabs/cloudwatch-logs-subscription-consumer
5. Scripts running from crontab to do Snapshots/backup/housekeeping

## Running the stack
The stack can be run manually via AWS console, or via aws-cli.

The one running ATM has been run manually using the following parameters:

```
AllowedIpSource	0.0.0.0/0
AMIID	ami-b9b09cda
AWSCloudPluginVersion	2.7.1
BuildId	3
CloudWatchConsumerCompiledZip	cloudwatch-logs-subscription-consumer-1.2.0
ClusterSize	2
CrossAccountID	018578619640
DefaultSecurityGroup	sg-98c4cffd
DNSDomain	cloudops.np.tu-aws.com
DNSZoneId	Z34K54PJ412ETK
ElasticSearchFilename	elasticsearch-1.7.3.noarch
ElasticsearchReplicas	1
ElasticsearchShards	5
ELBSSLCertificate	arn:aws:iam::300579097309:server-certificate/cloudopsnonprod.tu-aws.com
ESVolumeSize	200
ESVolumeSnapshotId	
HttpProxyHost	proxy.cloudops.np.tu-aws.com
HttpProxyPort	3128
IndexBackupRetentionDays	365
InstanceType	m4.large
KeyName	coreservices-nonprod-infra
Kibana3Filename	kibana-3.1.2
Kibana4Filename	kibana-4.1.6-linux-x64
KinesisShards	1
LogFormat	Custom
LogGroupNameRegex	
ManagedServicesTopicARN	arn:aws:sns:ap-southeast-2:300579097309:CloudOPS-Foundation-NonProduction
MonitorStack	true
NATSecurityGroup	sg-43584e26
NginxPassword	****
NginxUsername	nginx
RetentionDays	31
S3bucketBackup	cloudops-nonprod.backup.transurban.com
S3bucketSource	cloudops-nonprod.files.transurban.com
S3DownloadPath	CWL-consumer
S3IndexBackupPath	ELK-index
SnapRetentionDays	14
SubnetA	subnet-12a2ee77
SubnetB	subnet-341b6e43
SubscriptionFilterPattern	
TagApplication	ELK
TagEnvironment	dev
TagEnvironmentNumber	1
TagOwner	its@versent.com.au
TagRole	app
TagService	logging
TagTenant	Transurban
VPC	vpc-817411e4
``` 


## Issues
So far, if we run the stack it will fail to create LogDestination. It's nothing wrong with the cloudformation script, but more likely an undocumented issue within AWS. I've raised support case `1763807121: unable to create resource of type AWS::Logs::Destination`.  The reply was that the stack fails because it doesn't wait long enough for some supporting IAM role to be created and fails.

The workaround is: launch the stack **without** the `AWS::Logs::Destination` resource first, and when all is up and runing, just update the stack adding the resource back. 


## Usage
1. In order for the logs to end up and visualise in the Kibana board,  each CloudWatch loggroup that we need has to be **subscribed** to the Kinesis stream.

2. From the output section of CFN stack, extract the following info:

```
CrossDestinationARN ->	arn:aws:logs:ap-southeast-2:300579097309:destination:ELKCrossLogDestination-3
KinesisARN -> 	arn:aws:kinesis:ap-southeast-2:300579097309:stream/core-elk-1-dev-3-KinesisSubscriptionStream-U74VQVGK31AP
RoleARN ->	arn:aws:iam::300579097309:role/core-elk-1-dev-3-CloudWatchLogsKinesisRole-MO5NPEOCUCDB
``` 

3. Subscribing a loggroup can be done via aws-cli. There are 2 ways of doing the log subscription:
  - local (within the same AWS account):

**subscribe-local.sh**

```
#!/bin/bash -ex
group=$1
filter=$2
destarn='arn:aws:kinesis:ap-southeast-2:300579097309:stream/core-elk-1-dev-3-KinesisSubscriptionStream-U74VQVGK31AP'
rolearn='arn:aws:iam::300579097309:role/core-elk-1-dev-3-CloudWatchLogsKinesisRole-MO5NPEOCUCDB'
#destname='arn:aws:logs:ap-southeast-2:300579097309:destination:ELKCrossLogDestination-3'
aws logs put-subscription-filter \
  --log-group-name "$group" \
  --filter-name "ELK-filter-$group" \
  --destination-arn $destarn \
  --role-arn $rolearn \
  --filter-pattern "$filter"
  
```
Usage:
`./subscribe-local.sh 'loggroupname' '[field1, field2, fileld3]'`



  - cross-account (from separate AWS account):
**subscribe-cross.sh**
  
```
  #!/bin/bash -ex
group=$1
filter=$2
#destarn='arn:aws:kinesis:ap-southeast-2:300579097309:stream/core-elk-1-dev-3-KinesisSubscriptionStream-U74VQVGK31AP'
#rolearn='arn:aws:iam::300579097309:role/core-elk-1-dev-3-CloudWatchLogsKinesisRole-MO5NPEOCUCDB'
destname='arn:aws:logs:ap-southeast-2:300579097309:destination:ELKCrossLogDestination-3'
aws logs put-subscription-filter \
  --log-group-name "$group" \
  --filter-name "ELK-filter-$group" \
  --destination-arn $destname \
  --filter-pattern "$filter"
```
Usage:
`./subscribe-cross.sh 'loggroupname' '[field1, field2, fileld3]'`


## Authorise new AWS account to the kinesis stream (log destination)

1. describe the log destination:

```sh
aws logs describe-destinations
{
    "destinations": [
        {
            "roleArn": "arn:aws:iam::300579097309:role/core-elk-1-dev-3-CloudWatchLogsKinesisRole-MO5NPEOCUCDB",
            "creationTime": 1464749057362,
            "destinationName": "ELKCrossLogDestination-3",
            "accessPolicy": "{\n  \"Version\" : \"2012-10-17\",\n  \"Statement\" : [\n    {\n      \"Sid\" : \"\",\n      \"Effect\" : \"Allow\",\n      \"Principal\" : {\n        \"AWS\" : \"018578619640\"\n      },\n      \"Action\" : \"logs:PutSubscriptionFilter\",\n      \"Resource\" : \"arn:aws:logs:ap-southeast-2:300579097309:destination:ELKCrossLogDestination-3\"\n    },\n    {\n      \"Sid\" : \"\",\n      \"Effect\" : \"Allow\",\n      \"Principal\" : {\n        \"AWS\" : \"008399649760\"\n      },\n      \"Action\" : \"logs:PutSubscriptionFilter\",\n      \"Resource\" : \"arn:aws:logs:ap-southeast-2:300579097309:destination:ELKCrossLogDestination-3\"\n    }\n  ]\n}\n",
            "targetArn": "arn:aws:kinesis:ap-southeast-2:300579097309:stream/core-elk-1-dev-3-KinesisSubscriptionStream-U74VQVGK31AP",
            "arn": "arn:aws:logs:ap-southeast-2:300579097309:destination:ELKCrossLogDestination-3"
        }
    ]
}

```

2. Extract the access policy from the output:

```sh
"accessPolicy": "{\n  \"Version\" : \"2012-10-17\",\n  \"Statement\" : [\n    {\n      \"Sid\" : \"\",\n      \"Effect\" : \"Allow\",\n      \"Principal\" : {\n        \"AWS\" : \"018578619640\"\n      },\n      \"Action\" : \"logs:PutSubscriptionFilter\",\n      \"Resource\" : \"arn:aws:logs:ap-southeast-2:300579097309:destination:ELKCrossLogDestination-3\"\n    },\n    {\n      \"Sid\" : \"\",\n      \"Effect\" : \"Allow\",\n      \"Principal\" : {\n        \"AWS\" : \"008399649760\"\n      },\n      \"Action\" : \"logs:PutSubscriptionFilter\",\n      \"Resource\" : \"arn:aws:logs:ap-southeast-2:300579097309:destination:ELKCrossLogDestination-3\"\n    }\n  ]\n}\n",
```
this, expanding the newlines and removing prepended '\',  will render as:

```js
{
 "Version" : "2012-10-17",
 "Statement" : [
     {
        "Sid" : "",
        "Effect" : "Allow",
        "Principal" : { "AWS" : "018578619640" },
        "Action" : "logs:PutSubscriptionFilter",
        "Resource" : "arn:aws:logs:ap-southeast-2:300579097309:destination:ELKCrossLogDestination-3"
     },
     {
        "Sid" : "",
        "Effect" : "Allow",
        "Principal" : {"AWS" : "008399649760"},
        "Action" : "logs:PutSubscriptionFilter",
        "Resource" : "arn:aws:logs:ap-southeast-2:300579097309:destination:ELKCrossLogDestination-3"
      }
   ]
 }
```

3. Add the new cross-account ID to the policy, by copy one block and replace the Account ID:

```js
{
 "Version" : "2012-10-17",
 "Statement" : [
     {
        "Sid" : "",
        "Effect" : "Allow",
        "Principal" : { "AWS" : "018578619640" },
        "Action" : "logs:PutSubscriptionFilter",
        "Resource" : "arn:aws:logs:ap-southeast-2:300579097309:destination:ELKCrossLogDestination-3"
     },
     {
        "Sid" : "",
        "Effect" : "Allow",
        "Principal" : {"AWS" : "008399649760"},
        "Action" : "logs:PutSubscriptionFilter",
        "Resource" : "arn:aws:logs:ap-southeast-2:300579097309:destination:ELKCrossLogDestination-3"
      },
      {
        "Sid" : "",
        "Effect" : "Allow",
        "Principal" : {"AWS" : "785460830895"},
        "Action" : "logs:PutSubscriptionFilter",
        "Resource" : "arn:aws:logs:ap-southeast-2:300579097309:destination:ELKCrossLogDestination-3"
      }
   ]
 }

```

4. Update the destination log policy:
 - save te prepared policy at (3.) to a file (d.json in my case)
 - update the log destination:
```sh
aws logs put-destination-policy --destination-name ELKCrossLogDestination-3 --access-policy file://d.json
```

This is it. Now the log destination 'ELKCrossLogDestination-3' can be used from the new AWS account 785460830895
