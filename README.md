# Backendless Chef Stack

Cloudformation Templates to build out a complete Backendless Chef Configuration

**Note:** No longer requires a Cookbook to build.

## Info

-   Builds out customized Chef Server build out without any backends to zone lock your setup
-   Built to utilize Ubuntu Xenial
-   Allows you to choose versions to install on Chef-Server, Manage, and Reporting (Limited to Xenial Supported versions)
-   Builds out a RDS PostgreSQL Database, Version: 9.5.4
-   Builds out AWS Elasticsearch Domain (Node/Replication Configurable), Version: 2.3

## Diagram

![Alt text](backendless_chef.png?raw=true "Overview Diagram")

## Requirements

-   Existing VPC
    -   IP Scheme of 172.33.0.0/16 or modify template to support whichever (Take note of [Blue/Green](#subnet-switching) Section if changing)
    -   SSH Security Group (Will lookup existing groups in AWS, make sure one exists)
-   Route53 Hosted Domain/Zone; [Guide](http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/CreatingHostedZone.html)
-   Existing SSL Certificate (See [SSL Setup](#ssl-setup) Section for more info)

## Usage

### Getting Started

#### Required Options
Info you need to find/decide on to successfully build our Stack

-   Required Params to Fill Out
    -   HostedZone; A Domain Setup in Route53 [Guide](http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/CreatingHostedZone.html)
    -   SSLCertificateARN; See the [SSL Setup](#ssl-setup) Section
    -   LicenseCount; How many license you have purchased from Chef. (25 is the default, this is the amount of default "free" nodes you get starting off)
    -   DBUser; Username for DB (Required for Existing or New Setups)
    -   DBPassword; Password for DB (Required for Existing or New Setups)
-   Required Params to Select
    -   ChefSubdomain; See [Blue/Green](#bluegreen-deployment) Section for more Info
    -   ChefServerVersion; Select Version to install, versions listed are the only ones that have packages for Ubuntu Xenial
    -   ManageVersion; Select Version to install, versions listed are the only ones that have packages for Ubuntu Xenial
    -   ReportingVersion; Select Version to install, versions list are the only ones that support Elasticsearch
    -   DBMultiAZ; Select if you want the DB setup in Multiple Availability Zones
    -   ElasticInstanceType; Default is t2.small.elasticsearch, good for small or testing situations
    -   KeyName; Select SSH Key
    -   VPC; Select VPC to Build in
    -   SSHSecurityGroup; Select group for SSH access

#### Options for Larger Setups
These are the items to best look when round 5k Nodes checking in

-   Params to Change only if 4-5k+ Nodes (Estimated; still need to do actual load tests)
    -   DBInstanceType; Default (t2.large) is the minimum required for Chef DB Connections
    -   ESProxyInstanceType; Default is good for small-medium Chef Build Outs. Change as needed
    -   ElasticInstanceType; Default is probably not going to cut it for tons of requests
    -   DBMultiAZ; Would recommend setting this to true

#### Optional Setup

-   Restoring Setups; See the [Restore/Backup](#restorebackup-options) Section
-   NewRelic Setup; See the [NewRelic](#new-relic) Section
-   Sumologic Setup; See the [Sumologic](#sumologic) Section

##### Mail Server Setup
If you fill out the following Params the script will setup a postfix relay to allow the Chef Server to send email.

-   MailCreds; if the format `$username:$password`
-   MailHost; Such as mailgun.org
-   MailPort; Mail server port

##### Development Selections

Options that don't need to be bothered with except in development situations.

See [Contributing](#contributing) for how to contribute to this project

-   GitBranch; sets branch to pull scripts from
    -   Currently only affects NewRelic and Sumologic

### SSL Setup

To simplify the setup only the ELB (Public Side) is setup with SSL.

Learn how to upload certificates to be used with this [Guide](http://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_server-certs.html)

To Get an existing SSL Cert in AWS Follow this [Guide](http://docs.aws.amazon.com/cli/latest/reference/iam/get-server-certificate.html)

or run this command `aws iam get-server-certificate --server-certificate-name`

You can also use the new [AWS Certificate Manager Service](http://docs.aws.amazon.com/acm/latest/userguide/gs-acm.html) to create and manage certificates

### Blue/Green Deployment

This setup supports doing staged deploys and/or blue/green deployments

Below describes how this is accomplished, but there is a manual step require to complete the deploy.

-   Manual step
    -   Change `chef.$HostedZone` in Route53 to/from `chef-a.$HostedZone` or `chef-b.$HostedZone`


-   Blue/Green Options:
    -   ChefSubdomain Param; Enabled having a chef-a, chef-b, and even a chef-test subdomain created
        -   Subnets are changed based on these settings
    -   Server names are created based on the Subdomain and a prime chef.domain.com to support the multi-dns setup; [Code](aws_backendless_chef_ha.yml#L1149)
    -   There is a workaround for the odd cert creation caused by the multiple server name setup;
        -   Specify Cert Location: [Code 01](aws_backendless_chef_ha.yml#L1147-L1148)
        -   Copy badly name cert to expected one: [Code 02](aws_backendless_chef_ha.yml#L1194-L1200)

**In place upgrades are not supported yet.**

#### Subnet Switching

To support using the blue/green domains. There is a switch in place depending on if you select chef-a or chef-b
-   Subnet Section [Code 01](aws_backendless_chef_ha.yml#L357-L408)
-   Switch Command [Code 02](https://github.com/HearstAT/cfn_backendless_chef/blob/cfn_yml/aws_backendless_chef_ha.yml#L368)
-   Conditional [Code 03](aws_backendless_chef_ha.yml#L336-L337)

Chef-a has it's own set of subnets.

chef-b and chef-test chare subnets, as the intention for chef-test is to test your deploys/changes/etc in another region/vpc

### Restore/Backup Options

#### Database Snapshot

This is the simplest option from a all AWS standpoint. You also keep the same pivotal credentials

-   Required Items
    -   Existing S3 Bucket with:
        -   etc_opscode directory
        -   etc_reporting directory (can be empty)
        -   migration-level
    -   DB Snapshot (Same Region)
-   Required Params
    -   ExistingBucketName (e.g.; chef-data-bucket)
    -   DBSnapShot (e.g.; snaphot-date)

#### Knife EC Restore
If looking to change architecture, DB credentials, or even Pivotal then this is the best option.

This can be down outside the entire Cloudformation process, but if wanting to do it inline see below.

-   Required Items
    -   [knife ec](https://github.com/chef/knife-ec-backup) backup in a tar file
    -   Exisitng S3 Bucket with:
        -   chef_ec_backups folder
        -   Tar file from above in chef_ec_backups folder
-   Required Params
    -   ExistingBucketName (e.g.; chef-data-bucket)
    -   BackupFilename (e.g.; backup_$date.tar)

For External:

-   [knife ec](https://github.com/chef/knife-ec-backup) w/ the following items/info
    -   Backup (See backup command below)
    -   PostgreSQL Endpoint
    -   DB User
    -   DB Password
    -   webui_priv.pem (found in /etc/opscode on existing server or S3 sync bucket)
-   Command to run
    -   Backup: `knife ec backup /tmp/backup/ -s https://chef.hearst.at --webui-key /tmp/webui_priv.pem --with-user-sql --sql-host some-db.rds.amazonaws.com --sql-user dbuser --sql-password sup3rs3cr3ts`
    -   Restore: `knife ec restore /tmp/backup/ -s https://chef.hearst.at --webui-key /tmp/webui_priv.pem --with-user-sql --sql-host some-db.rds.amazonaws.com --sql-user dbuser --sql-password sup3rs3cr3ts`

## New Relic
We utilize New Relic as our APM and System Monitor, this is setup only if conditions are met

**If New Relic License Key Param is Filled Out**

-   What is Enabled:
    -   New Relic APM (Gem Packaged with Chef)
        -   Configured via [Code 01](newrelic.sh#L96-L110)
    -   NGINX Plugin via [MeetMe](https://github.com/MeetMe/newrelic-plugin-agent) Plugin Agent
        -   Configured via [Code 02](cfn_yml/newrelic.sh#L28-L74)
    -   New Relic [System Monitor](https://docs.newrelic.com/docs/servers/new-relic-servers-linux/getting-started/new-relic-servers-linux)
        -   Configured via [Code 03](newrelic.sh#L76-L94)

## Sumologic
We utilize Sumologic as our Log Management and Analytics platform, this is setup onl if conditions are met

**If Sumologic Access Key Param is Filled Out**

-   What is Enabled:
    -   Sumologic Collector
        -   Configured via [Code 01](sumologic.sh#L34-L40)
    -   Collection Sources
        -   Configured for Chef via [Code 02](sumologic.sh#L42-L218)
        -   Configured for Proxy via [Code 03](sumologic.sh#L220-L283)

## Contributing
#### External Contributors
-   Fork the repo on GitHub
-   Clone the project to your own machine
-   Commit changes to your own branch
-   Push your work back up to your fork
-   Submit a Pull Request so that we can review your changes

**NOTE:** Be sure to merge the latest from "upstream" before making a pull request!

#### Internal Contributors
-   Clone the project to your own machine
-   Create a new branch from master
-   Commit changes to your own branch
-   Push your work back up to your branch
-   Submit a Pull Request so the changes can be reviewed

**NOTE:** Be sure to merge the latest from "upstream" before making a pull request!

## Credits

Special Thanks to [Irving Popovetsky](https://github.com/irvingpop) for answering all my questions and being patient with me!

## License
Copyright 2016, Hearst Automation Team

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
