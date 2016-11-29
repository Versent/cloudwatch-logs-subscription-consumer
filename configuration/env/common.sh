export tgregion=ap-southeast-2
export AWS_DEFAULT_REGION=$tgregion
export AWS_REGION=$tgregion

CreateCrossLogDestination=true
CloudWatchConsumerCompiledZip="cloudwatch-logs-subscription-consumer-2.2.1"

KeyName="coreservices-$Environment-infra"
S3bucketBackup="cloudops-$Environment.backup.transurban.com"
S3bucketSource="cloudops-$Environment.files.transurban.com"
vpcname=coreservices-$Environment

privateasubnetname=${privateasubnetname:=$vpcname-private-a}
privatebsubnetname=${privatebsubnetname:=$vpcname-private-b}

#get required variables from the base versent network stack output, discovery is done via the stack name.
vpcid=`aws ec2 describe-vpcs --filters "Name=tag:Name,Values=$vpcname" --query Vpcs[].VpcId --output text`
subnetprivatea=`aws ec2 describe-subnets --filters Name=vpc-id,Values=$vpcid --filters "Name=tag:Name,Values=$privateasubnetname" --query Subnets[].SubnetId --output text`
subnetprivateb=`aws ec2 describe-subnets --filters Name=vpc-id,Values=$vpcid --filters "Name=tag:Name,Values=$privatebsubnetname" --query Subnets[].SubnetId --output text`

#extract the vpc default secirity group
defaultsg=`aws ec2 describe-security-groups --filters Name=vpc-id,Values=$vpcid --query 'SecurityGroups[].[GroupName,GroupId]' --output text | grep SecurityGroupDefault | awk  '{print $2}'`
natsg=`aws ec2 describe-security-groups --filters Name=vpc-id,Values=$vpcid --query 'SecurityGroups[].[GroupName,GroupId]' --output text | grep core-Squid-app | awk  '{print $2}'`

#extract the DNS domain name
DNSDomain=$(aws route53 get-hosted-zone --id $DNSZoneId --query 'HostedZone.Name' --output text | rev | cut -c 2- | rev)

export elballowedrange1='10.0.0.0/8'
export elballowedrange2='172.16.0.0/12'
export elballowedrange3='192.168.0.0/16'
#VPN Range
export elballowedrange4='10.153.16.128/26'
export elbexternalallowedrange='103.3.236.11/32'

AWSCloudPluginVersion="2.7.1"
BuildId=$StackNumber

ClusterSize="2"
DefaultSecurityGroup=$defaultsg
HttpProxyHost=none
HttpProxyPort=3128
ElasticSearchVersion=2.3.3
ElasticSearchFilename="elasticsearch-$ElasticSearchVersion"
ElasticsearchReplicas=1
ElasticsearchShards=5

ESVolumeSize=200
ESVolumeSnapshotId=''
IndexBackupRetentionDays=365
InstanceType="r3.xlarge"

Kibana3Filename="kibana-3.1.2"
Kibana4Filename="kibana-4.5.1-1.x86_64"
KinesisShards=1
LogFormat="Custom"
LogGroupNameRegex=''

MonitorStack="true"
NATSecurityGroup=$natsg
NginxPassword='nginx'
NginxUsername='nginx'
RetentionDays=31

S3DownloadPath="CWL-Consumer"
S3IndexBackupPath="ELK-index"
SnapRetentionDays=14
SubnetA=$subnetprivatea
SubnetB=$subnetprivateb
SubscriptionFilterPattern=''
TagApplication="ELK2"

TagEnvironmentNumber=1
TagOwner="its@versent.com.au"
TagRole="app"
TagService="logging"
TagTenant="Transurban"
VPC=$vpcid

elkstackname=$TagService-$TagApplication-$TagRole-$TagEnvironment-$TagEnvironmentNumber-$BuildId
