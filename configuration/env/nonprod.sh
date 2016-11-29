ManagedServicesTopicARN="arn:aws:sns:ap-southeast-2:300579097309:CloudOPS-Foundation-NonProduction"
ELBSSLCertificate="arn:aws:iam::300579097309:server-certificate/cloudopsnonprod.tu-aws.com"
TagEnvironment="dev"
DNSZoneId=Z34K54PJ412ETK
CrossAccountID="224667902588"
AMIID='ami-2b9daa48'

source env/common.sh

HttpProxyHost='proxy.cloudops.np.tu-aws.com'
LDAPGroup='CN=ACCESS-APP-ELK-NONPROD-ADMIN,OU=Security,OU=Groups,DC=transurban,DC=com,DC=au'
