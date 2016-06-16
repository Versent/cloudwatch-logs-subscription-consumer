#!/bin/bash -ex

export tgregion=ap-southeast-2
export AWS_DEFAULT_REGION=$tgregion
export AWS_REGION=$tgregion
export httpproxyhost='proxy.cloudops.tu-aws.com'
export ami=$amiid

cd configuration/cloudformation
#Workaround!!!
#Launch the stack with "CrossLogDestination" removed, then Update the Stack later
sed  '/"CrossLogDestination"/,/"CloudWatchLogsKinesisPolicy"/{/CloudWatchLogsKinesisPolicy/!d}' cwl-elasticsearch.json > cwl-elasticsearch-1.json


HttpProxyHost="proxy.cloudops.tu-aws.com"
KeyName="coreservices-$Environment-infra"
ManagedServicesTopicARN="arn:aws:sns:ap-southeast-2:770806701093:CloudOPS-Foundation-Production"
ELBSSLCertificate="arn:aws:iam::770806701093:server-certificate/star.cloudops.tu-aws.com"
S3bucketBackup="cloudops-$Environment.backup.transurban.com"
S3bucketSource="cloudops-$Environment.files.transurban.com"
TagEnvironment="prod"
DNSZoneId=Z1IQXR7V1TDWS7
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

AllowedIpSource="0.0.0.0/0"
AMIID="ami-b9b09cda"
AWSCloudPluginVersion="2.7.1"
BuildId=$BUILD_NUMBER
CloudWatchConsumerCompiledZip="cloudwatch-logs-subscription-consumer-1.2.0"
ClusterSize="2"
CrossAccountID="018578619640"
DefaultSecurityGroup=$defaultsg
HttpProxyPort=3128
ElasticSearchFilename="elasticsearch-1.7.3.noarch"
ElasticsearchReplicas=1
ElasticsearchShards=5

ESVolumeSize=200
ESVolumeSnapshotId=''
IndexBackupRetentionDays=365
InstanceType="m4.large"

Kibana3Filename="kibana-3.1.2"
Kibana4Filename="kibana-4.1.6-linux-x64"
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
TagApplication="ELK"

TagEnvironmentNumber=1
TagOwner="its@versent.com.au"
TagRole="app"
TagService="logging"
TagTenant="Transurban"
VPC=$vpcid

#Create the loggroup for ELK state in advance. Fail is Ok if the group already exists
set +e
aws logs create-log-group --log-group-name "$TagEnvironment#tufms.elk#elasticsearch-health.log"
set -e

if [ ! "$httpproxyhost" = "none" ]; then
  httpproxy="UsePreviousValue=true,ParameterKey=HttpProxyHost,ParameterValue=$httpproxyhost UsePreviousValue=true,ParameterKey=HttpProxyPort,ParameterValue=$HttpProxyPort"
fi

elkstackname=$TagService-$TagApplication-$TagRole-$TagEnvironment-$TagEnvironmentNumber-$BuildId

#launch stack
sed -ie 's/^ *//' cwl-elasticsearch-1.json
echo "Start Create Stack..."
aws cloudformation create-stack --capabilities CAPABILITY_IAM --disable-rollback \
  --stack-name "$elkstackname" \
  --template-body file://cwl-elasticsearch-1.json \
  --parameters $httpproxy \
UsePreviousValue=true,ParameterKey=AllowedIpSource,ParameterValue=$AllowedIpSource \
UsePreviousValue=true,ParameterKey=AMIID,ParameterValue=$AMIID \
UsePreviousValue=true,ParameterKey=AWSCloudPluginVersion,ParameterValue=$AWSCloudPluginVersion \
UsePreviousValue=true,ParameterKey=BuildId,ParameterValue=$BuildId \
UsePreviousValue=true,ParameterKey=CloudWatchConsumerCompiledZip,ParameterValue=$CloudWatchConsumerCompiledZip \
UsePreviousValue=true,ParameterKey=ClusterSize,ParameterValue=$ClusterSize \
UsePreviousValue=true,ParameterKey=CrossAccountID,ParameterValue=$CrossAccountID \
UsePreviousValue=true,ParameterKey=DefaultSecurityGroup,ParameterValue=$DefaultSecurityGroup \
UsePreviousValue=true,ParameterKey=DNSDomain,ParameterValue=$DNSDomain \
UsePreviousValue=true,ParameterKey=DNSZoneId,ParameterValue=$DNSZoneId \
UsePreviousValue=true,ParameterKey=ElasticSearchFilename,ParameterValue=$ElasticSearchFilename \
UsePreviousValue=true,ParameterKey=ElasticsearchReplicas,ParameterValue=$ElasticsearchReplicas \
UsePreviousValue=true,ParameterKey=ElasticsearchShards,ParameterValue=$ElasticsearchShards \
UsePreviousValue=true,ParameterKey=ELBSSLCertificate,ParameterValue=$ELBSSLCertificate \
UsePreviousValue=true,ParameterKey=ESVolumeSize,ParameterValue=$ESVolumeSize \
UsePreviousValue=true,ParameterKey=ESVolumeSnapshotId,ParameterValue=$ESVolumeSnapshotId \
UsePreviousValue=true,ParameterKey=IndexBackupRetentionDays,ParameterValue=$IndexBackupRetentionDays \
UsePreviousValue=true,ParameterKey=InstanceType,ParameterValue=$InstanceType \
UsePreviousValue=true,ParameterKey=KeyName,ParameterValue=$KeyName \
UsePreviousValue=true,ParameterKey=Kibana3Filename,ParameterValue=$Kibana3Filename \
UsePreviousValue=true,ParameterKey=Kibana4Filename,ParameterValue=$Kibana4Filename \
UsePreviousValue=true,ParameterKey=KinesisShards,ParameterValue=$KinesisShards \
UsePreviousValue=true,ParameterKey=LogFormat,ParameterValue=$LogFormat \
UsePreviousValue=true,ParameterKey=LogGroupNameRegex,ParameterValue=$LogGroupNameRegex \
UsePreviousValue=true,ParameterKey=ManagedServicesTopicARN,ParameterValue=$ManagedServicesTopicARN \
UsePreviousValue=true,ParameterKey=MonitorStack,ParameterValue=$MonitorStack \
UsePreviousValue=true,ParameterKey=NATSecurityGroup,ParameterValue=$NATSecurityGroup \
UsePreviousValue=true,ParameterKey=NginxPassword,ParameterValue=$NginxPassword \
UsePreviousValue=true,ParameterKey=NginxUsername,ParameterValue=$NginxUsername \
UsePreviousValue=true,ParameterKey=RetentionDays,ParameterValue=$RetentionDays \
UsePreviousValue=true,ParameterKey=S3bucketBackup,ParameterValue=$S3bucketBackup \
UsePreviousValue=true,ParameterKey=S3bucketSource,ParameterValue=$S3bucketSource \
UsePreviousValue=true,ParameterKey=S3DownloadPath,ParameterValue=$S3DownloadPath \
UsePreviousValue=true,ParameterKey=S3IndexBackupPath,ParameterValue=$S3IndexBackupPath \
UsePreviousValue=true,ParameterKey=SnapRetentionDays,ParameterValue=$SnapRetentionDays \
UsePreviousValue=true,ParameterKey=SubnetA,ParameterValue=$SubnetA \
UsePreviousValue=true,ParameterKey=SubnetB,ParameterValue=$SubnetB \
UsePreviousValue=true,ParameterKey=SubscriptionFilterPattern,ParameterValue=$SubscriptionFilterPattern \
UsePreviousValue=true,ParameterKey=TagApplication,ParameterValue=$TagApplication \
UsePreviousValue=true,ParameterKey=TagEnvironment,ParameterValue=$TagEnvironment \
UsePreviousValue=true,ParameterKey=TagEnvironmentNumber,ParameterValue=$TagEnvironmentNumber \
UsePreviousValue=true,ParameterKey=TagOwner,ParameterValue=$TagOwner \
UsePreviousValue=true,ParameterKey=TagRole,ParameterValue=$TagRole \
UsePreviousValue=true,ParameterKey=TagService,ParameterValue=$TagService \
UsePreviousValue=true,ParameterKey=TagTenant,ParameterValue=$TagTenant \
UsePreviousValue=true,ParameterKey=VPC,ParameterValue=$VPC




