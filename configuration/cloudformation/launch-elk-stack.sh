#!/bin/bash

set -eu -o pipefail

dir="$(readlink -f "$(dirname "$0")" )"
cd "$dir/.."
source "$dir/launch-stack.sh"

# cd "$dir/../.."
# #TEMP, include maven install and build the java app here
# mavenversion=3.3.9
# export MAVEN_OPTS="-Dhttps.proxyHost=$HttpProxyHost -Dhttps.proxyPort=3128 -Xmx512m"
# if [ ! -f apache-maven-$mavenversion-bin.tar.gz ]; then
  # wget http://mirror.ventraip.net.au/apache/maven/maven-3/$mavenversion/binaries/apache-maven-$mavenversion-bin.tar.gz
  # tar -xzvf apache-maven-$mavenversion-bin.tar.gz
# fi
#
# if [ -d target ]; then rm -rf target; fi
# if [ ! -f target/$CloudWatchConsumerCompiledZip-cfn.zip ]; then
  # #check if kinesis-connector is present
  # if [ ! -f ~/.m2/repository/com/amazonaws/amazon-kinesis-connectors/1.2.0/amazon-kinesis-connectors-1.2.0.jar ]; then
     # echo "Cannot find amazon-kinesis-connectors.jar, please run the job elk-compile-kinesis-jar first!"
     # exit 1
  # fi
  # rm -f configuration/cloudformation/*.rpm
  # apache-maven-3.3.9/bin/mvn clean install -Dgpg.skip=true
# fi
# # END TMP
#
# echo Uploading template to S3
# aws s3 cp "$dir/ca-api-stack.json" "s3://$s3bucket/CA/"
#
# if [ ! -f $Kibana4Filename.rpm ]; then
    # wget https://download.elastic.co/kibana/kibana/$Kibana4Filename.rpm
# fi
#
# if [ ! -f elasticsearch-$ElasticSearchVersion.rpm ]; then
    # wget https://download.elastic.co/elasticsearch/release/org/elasticsearch/distribution/rpm/elasticsearch/$ElasticSearchVersion/elasticsearch-$ElasticSearchVersion.rpm
# fi
# aws s3 cp target/$CloudWatchConsumerCompiledZip-cfn.zip s3://$S3bucketSource/$S3DownloadPath/
# aws s3 cp $Kibana4Filename.rpm s3://$S3bucketSource/$S3DownloadPath/
# aws s3 cp elasticsearch-$ElasticSearchVersion.rpm s3://$S3bucketSource/$S3DownloadPath/

cd "$dir"
aws s3 cp cwl-elasticsearch.json s3://$S3bucketSource/$S3DownloadPath/
#Create the loggroup for ELK state in advance. Fail is Ok if the group already exists
aws logs create-log-group --log-group-name "$TagEnvironment#tufms.elk#elasticsearch-health.log" || true

echo Uploading template to S3
aws s3 cp "$dir/cwl-elasticsearch.json" "s3://$S3bucketSource/$S3DownloadPath/"

#launch stack
echo "Start Create Stack..."
launch_stack "$elkstackname" "https://s3.amazonaws.com/$S3bucketSource/$S3DownloadPath/cwl-elasticsearch.json" \
  --capabilities CAPABILITY_IAM \
  --parameters \
    ParameterKey=HttpProxyHost,ParameterValue=$HttpProxyHost \
    ParameterKey=HttpProxyPort,ParameterValue=$HttpProxyPort \
    ParameterKey=CreateCrossLogDestination,ParameterValue=$CreateCrossLogDestination \
    ParameterKey=ELBAllowedRange1,ParameterValue=$elballowedrange1 \
    ParameterKey=ELBAllowedRange2,ParameterValue=$elballowedrange2 \
    ParameterKey=ELBAllowedRange3,ParameterValue=$elballowedrange3 \
    ParameterKey=ELBAllowedRange4,ParameterValue=$elballowedrange4 \
    ParameterKey=AMIID,ParameterValue=$AMIID \
    ParameterKey=BuildId,ParameterValue=$BuildId \
    ParameterKey=CloudWatchConsumerCompiledZip,ParameterValue=$CloudWatchConsumerCompiledZip \
    ParameterKey=ClusterSize,ParameterValue=$ClusterSize \
    ParameterKey=CrossAccountID,ParameterValue=$CrossAccountID \
    ParameterKey=DefaultSecurityGroup,ParameterValue=$DefaultSecurityGroup \
    ParameterKey=DNSDomain,ParameterValue=$DNSDomain \
    ParameterKey=DNSZoneId,ParameterValue=$DNSZoneId \
    ParameterKey=ElasticSearchFilename,ParameterValue=$ElasticSearchFilename \
    ParameterKey=ElasticsearchReplicas,ParameterValue=$ElasticsearchReplicas \
    ParameterKey=ElasticsearchShards,ParameterValue=$ElasticsearchShards \
    ParameterKey=ELBSSLCertificate,ParameterValue=$ELBSSLCertificate \
    ParameterKey=ESVolumeSize,ParameterValue=$ESVolumeSize \
    ParameterKey=ESVolumeSnapshotId,ParameterValue=$ESVolumeSnapshotId \
    ParameterKey=IndexBackupRetentionDays,ParameterValue=$IndexBackupRetentionDays \
    ParameterKey=InstanceType,ParameterValue=$InstanceType \
    ParameterKey=KeyName,ParameterValue=$KeyName \
    ParameterKey=Kibana3Filename,ParameterValue=$Kibana3Filename \
    ParameterKey=Kibana4Filename,ParameterValue=$Kibana4Filename \
    ParameterKey=KinesisShards,ParameterValue=$KinesisShards \
    ParameterKey=LogGroupNameRegex,ParameterValue=$LogGroupNameRegex \
    ParameterKey=ManagedServicesTopicARN,ParameterValue=$ManagedServicesTopicARN \
    ParameterKey=MonitorStack,ParameterValue=$MonitorStack \
    ParameterKey=NATSecurityGroup,ParameterValue=$NATSecurityGroup \
    ParameterKey=NginxPassword,ParameterValue=$NginxPassword \
    ParameterKey=NginxUsername,ParameterValue=$NginxUsername \
    ParameterKey=RetentionDays,ParameterValue=$RetentionDays \
    ParameterKey=S3bucketBackup,ParameterValue=$S3bucketBackup \
    ParameterKey=S3bucketSource,ParameterValue=$S3bucketSource \
    ParameterKey=S3DownloadPath,ParameterValue=$S3DownloadPath \
    ParameterKey=S3IndexBackupPath,ParameterValue=$S3IndexBackupPath \
    ParameterKey=SnapRetentionDays,ParameterValue=$SnapRetentionDays \
    ParameterKey=SubnetA,ParameterValue=$SubnetA \
    ParameterKey=SubnetB,ParameterValue=$SubnetB \
    ParameterKey=TagApplication,ParameterValue=$TagApplication \
    ParameterKey=TagEnvironment,ParameterValue=$TagEnvironment \
    ParameterKey=TagEnvironmentNumber,ParameterValue=$TagEnvironmentNumber \
    ParameterKey=TagOwner,ParameterValue=$TagOwner \
    ParameterKey=TagRole,ParameterValue=$TagRole \
    ParameterKey=TagService,ParameterValue=$TagService \
    ParameterKey=TagTenant,ParameterValue=$TagTenant \
    ParameterKey=VPC,ParameterValue=$VPC \

