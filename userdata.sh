#!/bin/bash -xev

#### UserData Backendless Chef Helper Script v 1.0
### Script Params, exported in Cloudformation
# ${REGION} == AWS::Region
# ${ACCESS_KEY} == AccessKey && ['aws_access_key_id']
# ${SECRET_KEY} == SecretKey && ['aws_secret_access_key']
# ${IAM_ROLE} == IAMRole
# ${DOMAIN} == HostedZone && ['domain']
# ${SECONDARY_DOMAIN} == SecondaryDomain
# ${SUBDOMAIN} == HostedSubdomain
# ${BUCKET} == ChefBucket || ExternalBucket
# ${BACKUP_ENABLE} == BackupEnable && ['backup']['enable_backups']
# ${EXISTING_INSTALL} == ExistingInstall
# ${CHEFDIR} == ChefDir
# ${S3DIR} == S3Dir
# ${ENABLE_SSL} == BackendSSL
# ${DB_USER} == DBUser
# ${DB_PASSWORD} == DBPassword
# ${DB_PORT} == DBPort
# ${DB_URL} == DBURL
# ${COOKBOOK} == Cookbook
# ${COOKBOOK_GIT} == CookbookGit
# ${COOKBOOK_BRANCH} == CookbookGitBranch
# ${SIGNUP_DISABLE} == SignupDisable && ['manage']['signupdisable']
# ${SUPPORT_EMAIL} == SupportEmail && ['manage']['supportemail']
# ${MAIL_HOST} == MailHost && ['mail']['relayhost']
# ${MAIL_PORT} == MailPort && ['mail']['relayport']
# ${MAIL_CREDS} == MailCreds
# ${NR_LICENSE} == NewRelicLicense
# ${NR_APPNAME} == NewRelicAppName
# ${NR_ENABLE} == NewRelicEnable
# ${SUMO_ENABLE} == SumologicEnable
# ${SUMO_ACCESS_ID} == SumologicAccessID
# ${SUMO_ACCESS_KEY} == SumologicAccessKey
# ${SUMO_PASSWORD} == SumologicPassword
# ${LICENSE_COUNT} == LicenseCount && ['licensecount']
###

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

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
if [ ! -d "${S3DIR}" ]; then
  mkdir ${S3DIR}
fi

# Mount S3 Bucket to Directory
s3fs -o allow_other -o umask=000 -o iam_role=${IAM_ROLE} -o endpoint=${REGION} ${BUCKET} ${S3DIR} || error_exit 'Failed to mount s3fs'

echo -e "${BUCKET} ${S3DIR} fuse.s3fs rw,_netdev,allow_other,umask=000,iam_role=${IAM_ROLE},endpoint=${REGION},retries=5,multireq_max=5 0 0" >> /etc/fstab || error_exit 'Failed to add mount info to fstab'

# Sleep to allow s3fs to connect
sleep 20

HOSTNAME="chef-fe-$(curl -sS http://169.254.169.254/latest/meta-data/instance-id)"
FQDN="chef-fe-$(curl -sS http://169.254.169.254/latest/meta-data/instance-id).${DOMAIN}"

if [ ${EXISTING_INSTALL} == 'false' ]; then
    if [ ! -f ${S3DIR}/master ]; then
        echo ${FQDN} > ${S3DIR}/master
    fi
    MASTER=$(cat ${S3DIR}/master)
else
    MASTER=NULL
fi

# make directories
mkdir -p ${S3DIR}/mail ${S3DIR}/newrelic ${S3DIR}/sumologic ${S3DIR}/db ${S3DIR}/aws ${S3DIR}/certs

## AWS Creds
echo "${ACCESS_KEY}" | tr -d '\n' > ${S3DIR}/aws/access_key
echo "${SECRET_KEY}" | tr -d '\n' > ${S3DIR}/aws/secret_key

## DB Creds
echo "${DB_USER}" | tr -d '\n' > ${S3DIR}/db/username
echo "${DB_PASSWORD}" | tr -d '\n' > ${S3DIR}/db/password

## Mail
echo "${MAIL_HOST} ${MAIL_CREDS}" | tr -d '\n' > ${S3DIR}/mail/creds

## New Relic
echo "${NR_LICENSE}" | tr -d '\n' > ${S3DIR}/newrelic/license

## Sumologic
echo "${SUMO_PASSWORD}" | tr -d '\n' > ${S3DIR}/sumologic/password
echo "${SUMO_ACCESS_ID}" | tr -d '\n' > ${S3DIR}/sumologic/access_id
echo "${SUMO_ACCESS_KEY}" | tr -d '\n' > ${S3DIR}/sumologic/access_key

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
mkdir -p ${CHEFDIR}
mkdir -p /etc/chef

# Set hostname
hostname ${FQDN}  || error_exit 'Failed to set hostname'
echo  ${FQDN}  > /etc/hostname || error_exit 'Failed to set hostname file'

cat > '/etc/hosts' << EOF
127.0.0.1 ${FQDN} ${HOSTNAME} localhost
::1 localhost6.localdomain6 localhost6
EOF


cat > "${CHEFDIR}/chef_stack.json" << EOF
{
    "citadel": {
        "bucket": "${BUCKET}"
    },
    "${COOKBOOK}": {
        "master": "${MASTER}",
        "backup": {
            "restore": false,
            "enable_backups": ${BACKUP_ENABLE}
        },
        "licensecount": "${LICENSE_COUNT}",
        "manage": {
            "signupdisable": ${SIGNUP_DISABLE},
            "supportemail": "${SUPPORT_EMAIL}"
        },
        "install": {
            "existing": ${EXISTING_INSTALL}
        },
        "mail": {
            "relayhost": "${MAIL_HOST}",
            "relayport": "${MAIL_PORT}"
        },
        "search": {
            "url": "${SEARCH_URL}"
        },
        "database": {
            "port": "${DB_PORT}",
            "url": "${DB_URL}"
        },
        "aws": {
            "region": "${REGION}"
        },
        "s3": {
            "dir": "${S3DIR}"
        },
        "ssl": {
            "enabled": ${ENABLE_SSL}
        },
        "newrelic": {
            "appname": "${NR_APPNAME}",
            "enable": ${NR_ENABLE}
        },
        "sumologic": {
            "enable": ${SUMO_ENABLE}
        },
        "api_fqdn": "chef.${DOMAIN}",
        "prime_domain": "${DOMAIN}",
        "secondary_domain": "${SECONDARY_DOMAIN}",
        "stage_subdomain": "${SUBDOMAIN}"
    },
    "run_list": [
        "recipe[apt-chef]",
        "recipe[chef-client]",
        "recipe[${COOKBOOK}]"
    ]
}
EOF

# Install berks
if [ ! -f "/opt/chef/embedded/bin/berks" ]; then
    /opt/chef/embedded/bin/gem install berkshelf
fi

# Copy json and setup for auto-restore option
cp ${CHEFDIR}/chef_stack.json ${CHEFDIR}/restore.json
sed -i 's/\"restore\": false/\"restore\": true/g' ${CHEFDIR}/restore.json
sed -i "s/${COOKBOOK}/${COOKBOOK}::restore/g" ${CHEFDIR}/restore.json

cat > ${CHEFDIR}/runner.json <<EOF
{"run_list":["recipe[apt-chef]","recipe[chef-client]"]}
EOF

# Prep for letsencrypt later
cat > /etc/chef/client.rb <<EOF
log_level        :info
log_location     STDOUT
cookbook_path "${CHEFDIR}/berks-cookbooks"
json_attribs "${CHEFDIR}/runner.json"
chef_zero.enabled
local_mode true
chef_zero.port 8899
EOF

# Switch to main directory
cd ${CHEFDIR}
cat > ${CHEFDIR}/client.rb <<EOF
log_level        :info
log_location     STDOUT
cookbook_path "${CHEFDIR}/berks-cookbooks"
json_attribs "${CHEFDIR}/chef_stack.json"
chef_zero.enabled
local_mode true
chef_zero.port 8899
EOF

cat > "${CHEFDIR}/Berksfile" <<EOF
source 'https://supermarket.chef.io'
cookbook "${COOKBOOK}", git: '${COOKBOOK_GIT}', branch: '${COOKBOOK_BRANCH}'
EOF

sudo su -l -c "cd ${CHEFDIR} && export BERKSHELF_PATH=${CHEFDIR} && /opt/chef/embedded/bin/berks vendor" || error_exit 'Berks Vendor failed to run'
sudo su -l -c "chef-client -c "${CHEFDIR}/client.rb"" || error_exit 'Failed to run chef-client'
