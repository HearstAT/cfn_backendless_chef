#!/bin/bash -xev

BUCKET="Fn::If": [ CreateChefBucket, ${ChefBucket}, ${BucketName} ]
ELASTICURL="Fn:GetAtt": [ ElasticsearchDomain, DomainEndpoint ]
DBENDPOINT="Fn::If": [ DBCon, ${DBURL}, "Fn::GetAtt": [ ChefDB, Endpoint.Address ] ]
DBPORT="Fn::If": [ DBCon, ${DBPort} , "Fn::GetAtt": [ ChefDB, Endpoint.Port ] ]

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

apt-get update && apt-get -y upgrade
apt-get install -y wget curl python-setuptools python-pip git

# Helper function to set wait timer
error_exit()
{
  /usr/local/bin/cfn-signal -e 1 -r $1 ${WaitHandle}
  exit 1
 }

# Install S3FS Dependencies
sudo apt-get install -y automake autotools-dev g++ git libcurl4-gnutls-dev libfuse-dev libssl-dev libxml2-dev make pkg-config

# Install S3FS

# If directory exists, remove it
if [ -d "/tmp/s3fs-fuse" ]; then
  rm -rf /tmp/s3fs-fuse
fi

# If s3fs command doesn't exist, install
if [ ! -f "/usr/local/bin/s3fs" ]; then
  cd /tmp
  git clone https://github.com/s3fs-fuse/s3fs-fuse.git || error_exit 'Failed to clone s3fs-fuse'
  cd s3fs-fuse
  ./autogen.sh || error_exit 'Failed to run autogen for s3fs-fuse'
  ./configure || error_exit 'Failed to run configure for s3fs-fuse'
  make || error_exit 'Failed to make s3fs-fuse'
  sudo make install || error_exit 'Failed run make-install s3fs-fuse'
fi

# Create S3FS Mount Directory
if [ ! -d "${S3Dir}" ]; then
  mkdir ${S3Dir}
fi

# Mount S3 Bucket to Directory
s3fs -o allow_other -o umask=000 -o iam_role=${ChefRole} -o endpoint=${AWS::Region} $BUCKET ${S3Dir} || error_exit 'Failed to mount s3fs'

echo -e "$BUCKET ${S3Dir} fuse.s3fs rw,_netdev,allow_other,umask=000,iam_role=${ChefRole},endpoint=${AWS::Region},retries=5,multireq_max=5 0 0" >> /etc/fstab || error_exit 'Failed to add mount info to fstab'

# Sleep to allow s3fs to connect
sleep 20

HOSTNAME="chef-fe-$(curl -sS http://169.254.169.254/latest/meta-data/instance-id)"
FQDN="chef-fe-$(curl -sS http://169.254.169.254/latest/meta-data/instance-id).${HostedZone}"

if [ ${ExistingInstall} == 'false' ]; then
    if [ ! -f ${S3Dir}/master ]; then
        echo $FQDN > ${S3Dir}/master
    fi
    MASTER=$(cat ${S3Dir}/master)
else
    MASTER=NULL
fi

# make directories
mkdir -p ${S3Dir}/mail ${S3Dir}/newrelic ${S3Dir}/sumologic ${S3Dir}/db ${S3Dir}/certs

set +xv
## DB Creds
echo "${DBUser}" | tr -d '\n' > ${S3Dir}/db/username
echo "${DBPassword}" | tr -d '\n' > ${S3Dir}/db/password

## Mail
echo "${MailHost} ${MailCreds}" | tr -d '\n' > ${S3Dir}/mail/creds

## New Relic
echo "${NewRelicLicense}" | tr -d '\n' > ${S3Dir}/newrelic/license

## Sumologic
echo "${SumologicPassword}" | tr -d '\n' > ${S3Dir}/sumologic/password
echo "${SumologicAccessID}" | tr -d '\n' > ${S3Dir}/sumologic/access_id
echo "${SumologicAccessKey}" | tr -d '\n' > ${S3Dir}/sumologic/access_key
set -xv

# install chef
if [ ! -f "/usr/bin/chef-client" ]; then
    curl -L https://omnitruck.chef.io/install.sh | bash || error_exit 'could no install chef'
fi

# Install cfn bootstraping tools
if [ ! -f "/usr/local/bin/cfn-signal" ]; then
    easy_install https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-latest.tar.gz || error_exit "could not install cfn bootstrap tools"
fi

if [ ! -d "/etc/chef/ohai/hints" ]; then
    mkdir -p /etc/chef/ohai/hints || error_exit 'Failed to create ohai folder'
fi

touch /etc/chef/ohai/hints/ec2.json || error_exit 'Failed to create ec2 hint file'
touch /etc/chef/ohai/hints/iam.json || error_exit 'Failed to create iam hint file'

# Create Chef Directory
if [ ! -d "${ChefDir}" ]; then
  mkdir -p ${ChefDir}
fi

if [ ! -d '/etc/chef']; then
  mkdir -p /etc/chef
fi

# Set hostname
hostname $FQDN  || error_exit 'Failed to set hostname'
echo  $FQDN  > /etc/hostname || error_exit 'Failed to set hostname file'

cat > '/etc/hosts' << EOF
127.0.0.1 $FQDN $HOSTNAME localhost
::1 localhost6.localdomain6 localhost6
EOF


cat > ${ChefDir}/chef_stack.json << EOF
{
    "citadel": {
        "bucket": "$BUCKET"
    },
    "${Cookbook}": {
        "master": "$MASTER",
        "backup": {
            "enable_backups": ${BackupEnable}
        },
        "version": {
            "server": ${ChefServerVersion},
            "reporting": ${ReportingVersion},
            "manage": ${ManageVersion}
        },
        "licensecount": "${LicenseCount}",
        "manage": {
            "signupdisable": ${SignupDisable},
            "supportemail": "${SupportEmail}"
        },
        "install": {
            "existing": ${ExistingInstall}
        },
        "mail": {
            "relayhost": "${MailHost}",
            "relayport": "${MailPort}"
        },
        "search": {
            "url": "$ELASTICURL"
        },
        "database": {
            "port": "$DBPORT",
            "url": "$DBENDPOINT"
        },
        "aws": {
            "AWS::Region": "${AWS::Region}"
        },
        "s3": {
            "dir": "${S3Dir}"
        },
        "ssl": {
            "enabled": ${BackendSSL}
        },
        "newrelic": {
            "appname": "${NewRelicAppName}",
            "enable": ${NewRelicEnable}
        },
        "sumologic": {
            "enable": ${SumologicEnable}
        },
        "api_fqdn": "chef.${HostedZone}",
        "prime_domain": "${HostedZone}",
        "stage_subdomain": "${ChefSubdomain}"
    },
    "run_list": [
        "recipe[apt-chef]",
        "recipe[chef-client]",
        "recipe[${Cookbook}]"
    ]
}
EOF

# Install berks
if [ ! -f "/opt/chef/embedded/bin/berks" ]; then
    /opt/chef/embedded/bin/gem install berkshelf
fi

# Copy json and setup for auto-restore option
cp ${ChefDir}/chef_stack.json ${ChefDir}/restore.json
sed -i "s/${Cookbook}/${Cookbook}::restore/g" ${ChefDir}/restore.json

cat > ${ChefDir}/runner.json <<EOF
{"run_list":["recipe[apt-chef]","recipe[chef-client]"]}
EOF

# Prep for letsencrypt later
cat > /etc/chef/client.rb <<EOF
log_level        :info
log_location     STDOUT
cookbook_path "${ChefDir}/berks-cookbooks"
json_attribs "${ChefDir}/runner.json"
chef_zero.enabled
local_mode true
chef_zero.port 8899
EOF

# Switch to main directory
cd ${ChefDir}
cat > ${ChefDir}/client.rb <<EOF
log_level        :info
log_location     STDOUT
cookbook_path "${ChefDir}/berks-cookbooks"
json_attribs "${ChefDir}/chef_stack.json"
chef_zero.enabled
local_mode true
chef_zero.port 8899
EOF

cat > "${ChefDir}/Berksfile" <<EOF
source 'https://supermarket.chef.io'
cookbook "${Cookbook}", git: '${CookbookGit}', branch: '${CookbookGitBranch}'
EOF

sudo su -l -c "cd ${ChefDir} && export BERKSHELF_PATH=${ChefDir} && /opt/chef/embedded/bin/berks vendor" || error_exit 'Berks Vendor failed to run'
sudo su -l -c "chef-client -c "${ChefDir}/client.rb"" || error_exit 'Failed to run chef-client'

# All is well so signal success and let CF know wait function is complete
/usr/local/bin/cfn-signal -e 0 -r 'Server setup complete' ${WaitHandle}
