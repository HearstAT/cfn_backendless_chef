#!/usr/bin/env ruby

require 'bundler/setup'
require 'cloudformation-ruby-dsl/cfntemplate'
require 'cloudformation-ruby-dsl/spotprice'
require 'cloudformation-ruby-dsl/table'

template do

  value :AWSTemplateFormatVersion => '2010-09-09'

  value :Description => 'Cloudformation Backendless Chef v1.0'

  parameter 'HostedZone',
            :Type => 'String',
            :Default => 'domain.com',
            :Description => 'must match a route53 hosted domain/zone'

  parameter 'SecondaryDomain',
            :Type => 'String',
            :Default => 'domain.com',
            :Description => 'If including a 2nd manual/non-aws domain (optional)'

  parameter 'UseAdditionalDomain',
            :Type => 'String',
            :Default => 'true',
            :AllowedValues => [ 'true', 'false' ],
            :Description => 'Choose to use a Second Domain, will generate another ELB and require another ssl arn'

  parameter 'BackendSSL',
            :Type => 'String',
            :Default => 'true',
            :AllowedValues => [ 'true', 'false' ],
            :Description => 'Choose to use backend ssl in addition to ELB ssl'

  parameter 'ChefSubdomain',
            :Type => 'String',
            :Default => 'chef-a',
            :AllowedValues => [ 'chef-a', 'chef-b' ],
            :Description => 'subdomain/prefix for chose hosted zone used for staging'

  parameter 'SSLCertificateARN',
            :Type => 'String',
            :Default => 'arn:aws:iam::',
            :Description => 'SSL Certficate ARN for SSL Certficate'

  parameter 'SecondarySSLCertificateARN',
            :Type => 'String',
            :Default => 'arn:aws:iam::',
            :Description => 'Secondary SSL Certficate ARN for SSL Certficate'

  parameter 'SignupDisable',
            :Type => 'String',
            :Default => 'true',
            :AllowedValues => [ 'true', 'false' ],
            :Description => 'Enter True/False for signup disable (false by default)'

  parameter 'SupportEmail',
            :Type => 'String',
            :Default => 'atat@hearst.com',
            :Description => 'Enter Support Email for Chef Server (Optional)'

  parameter 'MailHost',
            :Type => 'String',
            :Default => 'smtp.mailgun.org',
            :Description => 'Enter Mail Host (Optional)'

  parameter 'MailPort',
            :Type => 'String',
            :Default => '587',
            :Description => 'Enter Port for Mail Host (Optional)'

  parameter 'ChefDir',
            :Type => 'String',
            :Default => '/root/chef',
            :Description => 'Enter location for client.rb, role.json, & berks functions/creation'

  parameter 'LicenseCount',
            :Type => 'String',
            :Default => '25',
            :Description => 'Enter how many licenses you have purchased'

  parameter 'DBUser',
            :Type => 'String',
            :Default => '',
            :Description => 'Enter DB User Name'

  parameter 'DBPassword',
            :Type => 'String',
            :NoEcho => 'true',
            :Default => '',
            :Description => 'Enter DB Password'

  parameter 'DBPort',
            :Type => 'String',
            :Default => '5432',
            :Description => 'Enter DB Port'

  parameter 'DBURL',
            :Type => 'String',
            :Default => '',
            :Description => 'Enter DB URL or VIP'

  parameter 'ElasticSearchURL',
            :Type => 'String',
            :Default => '',
            :Description => 'Enter ElasticSearch URL'

  parameter 'UseExistingBucket',
            :Type => 'String',
            :Default => 'true',
            :AllowedValues => [ 'true', 'false' ],
            :Description => 'Choose to use an existing bucket from previous installation'

  parameter 'BucketName',
            :Type => 'String',
            :Default => '',
            :Description => 'Leave Empty! Unless using existing bucket, then enter bucket name here'

  parameter 'ExistingInstall',
            :Type => 'String',
            :Default => 'true',
            :AllowedValues => [ 'true', 'false' ],
            :Description => 'Choose only if existing install (i.e.; Previous External DB and Existing S3 Bucket)'

  parameter 'MailCreds',
            :Type => 'String',
            :NoEcho => 'true',
            :Default => '',
            :Description => 'Enter Mail Credentials (e.g.; $username:$password)'

  parameter 'NewRelicAppName',
            :Type => 'String',
            :Default => 'chef_ha_stack',
            :Description => 'Enter New Relic Application Name'

  parameter 'NewRelicLicense',
            :Type => 'String',
            :NoEcho => 'true',
            :Default => '',
            :Description => 'Enter New Relic License Key'

  parameter 'NewRelicEnable',
            :Type => 'String',
            :Default => 'true',
            :AllowedValues => [ 'true', 'false' ],
            :Description => 'Choose to enable/disable New Relic'

  parameter 'SumologicEnable',
            :Type => 'String',
            :Default => 'true',
            :AllowedValues => [ 'true', 'false' ],
            :Description => 'Choose to enable/disable Sumologic'

  parameter 'SumologicAccessID',
            :Type => 'String',
            :NoEcho => 'true',
            :Default => '',
            :Description => 'Enter Sumologic Access ID'

  parameter 'SumologicAccessKey',
            :Type => 'String',
            :NoEcho => 'true',
            :Default => '',
            :Description => 'Enter Sumologic Access Key'

  parameter 'SumologicPassword',
            :Type => 'String',
            :NoEcho => 'true',
            :Default => '',
            :Description => 'Enter Sumologic Password'

  parameter 'S3Dir',
            :Type => 'String',
            :Default => '/opt/chef-s3',
            :Description => 'Path to mount S3 Bucket to (created during CFN run)'

  parameter 'Cookbook',
            :Type => 'String',
            :Default => 'backendless_chef',
            :Description => 'Cookbook Name'

  parameter 'CookbookGit',
            :Type => 'String',
            :Default => 'https://github.com/HearstAT/cookbook_backendless_chef',
            :Description => 'Git Clone URI for Cookbook'

  parameter 'CookbookGitBranch',
            :Type => 'String',
            :Default => 'master',
            :Description => 'Git Clone Branch'

  parameter 'KeyName',
            :Description => 'Name of an existing EC2 KeyPair to enable SSH access to the instance',
            :Type => 'AWS::EC2::KeyPair::KeyName'

  parameter 'SSHSecurityGroup',
            :Description => 'Select Security Group for SSH Access',
            :Type => 'AWS::EC2::SecurityGroup::Id',
            :Default => ''

  parameter 'UserDataScript',
            :Type => 'String',
            :Default => 'https://raw.githubusercontent.com/HearstAT/cfn_backendless_chef/master/userdata.sh',
            :Description => 'URL for userdata script to run'

  parameter 'BackupEnable',
            :Type => 'String',
            :Default => 'true',
            :AllowedValues => [ 'true', 'false' ],
            :Description => 'Select True/False if you wanted to enable backups'

  parameter 'VPC',
            :Description => 'Choose VPC to use',
            :Type => 'AWS::EC2::VPC::Id',
            :Default => ''

  parameter 'AvailabilityZoneA',
            :Description => 'Choose Availability Zone to use',
            :Type => 'AWS::EC2::AvailabilityZone::Name',
            :Default => ''

  parameter 'AvailabilityZoneB',
            :Description => 'Choose Availability Zone to use',
            :Type => 'AWS::EC2::AvailabilityZone::Name',
            :Default => ''

  parameter 'AvailabilityZoneC',
            :Description => 'Choose Availability Zone to use',
            :Type => 'AWS::EC2::AvailabilityZone::Name',
            :Default => ''

  parameter 'InstanceType',
            :Type => 'String',
            :Default => 'c4.large',
            :AllowedValues => [
                'm3.medium',
                'm3.large',
                'm3.xlarge',
                'm3.2xlarge',
                'c3.large',
                'c3.xlarge',
                'c3.2xlarge',
                'c3.4xlarge',
                'c3.8xlarge',
                'c4.large',
                'c4.xlarge',
                'c4.2xlarge',
                'c4.4xlarge',
                'c4.8xlarge',
                'g2.2xlarge',
                'r3.large',
                'r3.xlarge',
                'r3.2xlarge',
                'r3.4xlarge',
                'r3.8xlarge',
                'i2.xlarge',
                'i2.2xlarge',
                'i2.4xlarge',
                'i2.8xlarge',
                'd2.xlarge',
                'd2.2xlarge',
                'd2.4xlarge',
                'd2.8xlarge',
                'hi1.4xlarge',
                'hs1.8xlarge',
                'cr1.8xlarge',
                'cc2.8xlarge',
                'cg1.4xlarge',
            ],
            :ConstraintDescription => 'must be a valid EC2 instance type.'

  value :Metadata => {
      :'AWS::CloudFormation::Interface' => {
          :ParameterGroups => [
              {
                  :Label => { :default => 'Domain Configuration' },
                  :Parameters => [ 'HostedZone', 'SSLCertificateARN', 'UseAdditionalDomain', 'SecondaryDomain', 'SecondarySSLCertificateARN' ],
              },
              {
                  :Label => { :default => 'Bucket Configuration' },
                  :Parameters => [ 'UseExistingBucket', 'BucketName' ],
              },
              {
                  :Label => { :default => 'Re-Deploy Configuration (When Using Existing Items)' },
                  :Parameters => [ 'ExistingInstall' ],
              },
              {
                  :Label => { :default => 'Chef Configuration' },
                  :Parameters => [ 'ChefSubdomain', 'SignupDisable', 'SupportEmail', 'LicenseCount', 'ChefDir', 'S3Dir', 'BackupEnable' ],
              },
              {
                  :Label => { :default => 'Database Configuration' },
                  :Parameters => [ 'DBUser', 'DBPassword', 'DBPort', 'DBURL' ],
              },
              {
                  :Label => { :default => 'ElasticSearch Configuration' },
                  :Parameters => [ 'ElasticSearchURL' ],
              },
              {
                  :Label => { :default => 'Mail Configuration (Optional)' },
                  :Parameters => [ 'MailCreds', 'MailHost', 'MailPort' ],
              },
              {
                  :Label => { :default => 'New Relic Configuration (Optional)' },
                  :Parameters => [ 'NewRelicEnable', 'NewRelicAppName', 'NewRelicLicense' ],
              },
              {
                  :Label => { :default => 'Sumologic Configuration (Optional)' },
                  :Parameters => [ 'SumologicEnable', 'SumologicAccessID', 'SumologicAccessKey', 'SumologicPassword' ],
              },
              {
                  :Label => { :default => 'External Build Items' },
                  :Parameters => [ 'Cookbook', 'CookbookGit', 'CookbookGitBranch', 'UserDataScript' ],
              },
              {
                  :Label => { :default => 'Instance & Network Configuration' },
                  :Parameters => [
                      'InstanceType',
                      'BackendSSL',
                      'KeyName',
                      'VPC',
                      'SSHSecurityGroup',
                      'AvailabilityZoneA',
                      'AvailabilityZoneB',
                      'AvailabilityZoneC',
                  ],
              },
          ],
      },
  }

  mapping 'AWSInstanceType2Arch',
          :'t2.medium' => { :Arch => 'HVM64' },
          :'t2.large' => { :Arch => 'HVM64' },
          :'m1.small' => { :Arch => 'HVM64' },
          :'m1.medium' => { :Arch => 'HVM64' },
          :'m1.large' => { :Arch => 'HVM64' },
          :'m1.xlarge' => { :Arch => 'HVM64' },
          :'m2.xlarge' => { :Arch => 'HVM64' },
          :'m2.2xlarge' => { :Arch => 'HVM64' },
          :'m2.4xlarge' => { :Arch => 'HVM64' },
          :'m3.medium' => { :Arch => 'HVM64' },
          :'m3.large' => { :Arch => 'HVM64' },
          :'m3.xlarge' => { :Arch => 'HVM64' },
          :'m3.2xlarge' => { :Arch => 'HVM64' },
          :'m4.large' => { :Arch => 'HVM64' },
          :'m4.xlarge' => { :Arch => 'HVM64' },
          :'m4.2xlarge' => { :Arch => 'HVM64' },
          :'m4.4xlarge' => { :Arch => 'HVM64' },
          :'m4.10xlarge' => { :Arch => 'HVM64' },
          :'c1.medium' => { :Arch => 'HVM64' },
          :'c1.xlarge' => { :Arch => 'HVM64' },
          :'c3.large' => { :Arch => 'HVM64' },
          :'c3.xlarge' => { :Arch => 'HVM64' },
          :'c3.2xlarge' => { :Arch => 'HVM64' },
          :'c3.4xlarge' => { :Arch => 'HVM64' },
          :'c3.8xlarge' => { :Arch => 'HVM64' },
          :'c4.large' => { :Arch => 'HVM64' },
          :'c4.xlarge' => { :Arch => 'HVM64' },
          :'c4.2xlarge' => { :Arch => 'HVM64' },
          :'c4.4xlarge' => { :Arch => 'HVM64' },
          :'c4.8xlarge' => { :Arch => 'HVM64' },
          :'g2.2xlarge' => { :Arch => 'HVM64' },
          :'g2.8xlarge' => { :Arch => 'HVM64' },
          :'r3.large' => { :Arch => 'HVM64' },
          :'r3.xlarge' => { :Arch => 'HVM64' },
          :'r3.2xlarge' => { :Arch => 'HVM64' },
          :'r3.4xlarge' => { :Arch => 'HVM64' },
          :'r3.8xlarge' => { :Arch => 'HVM64' },
          :'i2.xlarge' => { :Arch => 'HVM64' },
          :'i2.2xlarge' => { :Arch => 'HVM64' },
          :'i2.4xlarge' => { :Arch => 'HVM64' },
          :'i2.8xlarge' => { :Arch => 'HVM64' },
          :'d2.xlarge' => { :Arch => 'HVM64' },
          :'d2.2xlarge' => { :Arch => 'HVM64' },
          :'d2.4xlarge' => { :Arch => 'HVM64' },
          :'d2.8xlarge' => { :Arch => 'HVM64' },
          :'hi1.4xlarge' => { :Arch => 'HVM64' },
          :'hs1.8xlarge' => { :Arch => 'HVM64' },
          :'cr1.8xlarge' => { :Arch => 'HVM64' },
          :'cc2.8xlarge' => { :Arch => 'HVM64' }

  mapping 'AWSRegionArch2AMI',
          :'us-east-1' => { :HVM64 => 'ami-0021766a' },
          :'us-west-2' => { :HVM64 => 'ami-dbfc02bb' },
          :'us-west-1' => { :HVM64 => 'ami-56f59e36' },
          :'eu-west-1' => { :HVM64 => 'ami-a11dbfd2' },
          :'eu-central-1' => { :HVM64 => 'ami-ffaab693' },
          :'ap-northeast-1' => { :HVM64 => 'ami-20b98c4e' },
          :'ap-southeast-1' => { :HVM64 => 'ami-06834165' },
          :'ap-southeast-2' => { :HVM64 => 'ami-7bbee518' },
          :'sa-east-1' => { :HVM64 => 'ami-08bd3a64' },
          :'cn-north-1' => { :HVM64 => 'ami-3378b15e' }

  mapping 'SubnetConfig',
          :PublicA => { :CIDR => '172.33.10.0/24' },
          :PublicB => { :CIDR => '172.33.20.0/24' },
          :PublicC => { :CIDR => '172.33.30.0/24' }

  condition 'CreateChefBucket',
            :'Fn::Equals' => [
                ref('UseExistingBucket'),
                'false',
            ]

  condition 'SecondaryDomainCon',
            :'Fn::Equals' => [
                ref('UseAdditionalDomain'),
                'true',
            ]

  condition 'SingleDomainCon',
            :'Fn::Equals' => [
                ref('UseAdditionalDomain'),
                'false',
            ]

  condition 'BackendSSLCon',
            :'Fn::Equals' => [
                ref('BackendSSL'),
                'true',
            ]

  resource 'SubnetA', :Type => 'AWS::EC2::Subnet', :Properties => {
      :VpcId => ref('VPC'),
      :AvailabilityZone => ref('AvailabilityZoneA'),
      :CidrBlock => find_in_map('SubnetConfig', 'PublicA', 'CIDR'),
      :Tags => [
          { :Key => 'Name', :Value => 'Chef-Public-Subnet' },
          {
              :Key => 'Application',
              :Value => aws_stack_id,
          },
          { :Key => 'Network', :Value => 'Public' },
      ],
  }

  resource 'SubnetB', :Type => 'AWS::EC2::Subnet', :Properties => {
      :VpcId => ref('VPC'),
      :AvailabilityZone => ref('AvailabilityZoneB'),
      :CidrBlock => find_in_map('SubnetConfig', 'PublicB', 'CIDR'),
      :Tags => [
          { :Key => 'Name', :Value => 'Chef-Public-Subnet' },
          {
              :Key => 'Application',
              :Value => aws_stack_id,
          },
          { :Key => 'Network', :Value => 'Public' },
      ],
  }

  resource 'SubnetC', :Type => 'AWS::EC2::Subnet', :Properties => {
      :VpcId => ref('VPC'),
      :AvailabilityZone => ref('AvailabilityZoneC'),
      :CidrBlock => find_in_map('SubnetConfig', 'PublicC', 'CIDR'),
      :Tags => [
          { :Key => 'Name', :Value => 'Chef-Public-Subnet' },
          {
              :Key => 'Application',
              :Value => aws_stack_id,
          },
          { :Key => 'Network', :Value => 'Public' },
      ],
  }

  resource 'ChefBucket', :Type => 'AWS::S3::Bucket', :Condition => 'CreateChefBucket', :DeletionPolicy => 'Retain', :Properties => { :AccessControl => 'Private' }

  resource 'ChefRole', :Type => 'AWS::IAM::Role', :Properties => {
      :AssumeRolePolicyDocument => {
          :Version => '2012-10-17',
          :Statement => [
              {
                  :Effect => 'Allow',
                  :Principal => { :Service => [ 'ec2.amazonaws.com' ] },
                  :Action => [ 'sts:AssumeRole' ],
              },
          ],
      },
      :Path => '/',
  }

  resource 'RolePolicies', :Type => 'AWS::IAM::Policy', :Properties => {
      :PolicyName => 'chef-s3',
      :PolicyDocument => {
          :Version => '2012-10-17',
          :Statement => [
              {
                  :Effect => 'Allow',
                  :Action => [ 's3:*' ],
                  :Resource => [
                      join('', 'arn:aws:s3:::', { :'Fn::If' => [ 'CreateChefBucket', ref('ChefBucket'), ref('BucketName') ] }),
                      join('', 'arn:aws:s3:::', { :'Fn::If' => [ 'CreateChefBucket', ref('ChefBucket'), ref('BucketName') ] }, '/*'),
                  ],
              },
              {
                  :Effect => 'Allow',
                  :Action => [ 's3:List*' ],
                  :Resource => 'arn:aws:s3:::*',
              },
          ],
      },
      :Roles => [ ref('ChefRole') ],
  }

  resource 'ChefInstanceProfile', :Type => 'AWS::IAM::InstanceProfile', :Properties => {
      :Path => '/',
      :Roles => [ ref('ChefRole') ],
  }

  resource 'LoadBalancerSecurityGroup', :Type => 'AWS::EC2::SecurityGroup', :Properties => {
      :GroupDescription => 'Setup Ingress/Egress for Chef Frontend Load Balancer',
      :VpcId => ref('VPC'),
      :SecurityGroupIngress => [
          { :IpProtocol => 'tcp', :FromPort => '80', :ToPort => '80', :CidrIp => '0.0.0.0/0' },
          { :IpProtocol => 'tcp', :FromPort => '443', :ToPort => '443', :CidrIp => '0.0.0.0/0' },
      ],
      :SecurityGroupEgress => [
          { :IpProtocol => 'tcp', :FromPort => '0', :ToPort => '65535', :CidrIp => '0.0.0.0/0' },
      ],
      :Tags => [
          { :Key => 'Name', :Value => 'Chef-ELB-SecurityGroup' },
      ],
  }

  resource 'PrimaryElasticLoadBalancer', :Type => 'AWS::ElasticLoadBalancing::LoadBalancer', :Properties => {
      :Subnets => [
          ref('SubnetA'),
          ref('SubnetB'),
          ref('SubnetC'),
      ],
      :SecurityGroups => [ ref('LoadBalancerSecurityGroup') ],
      :LBCookieStickinessPolicy => [
          { :PolicyName => 'PublicELBCookieStickinessPolicy', :CookieExpirationPeriod => '3600' },
      ],
      :Listeners => [
          {
              :InstancePort => { :'Fn::If' => [ 'BackendSSLCon', '443', '80' ] },
              :LoadBalancerPort => '443',
              :InstanceProtocol => 'HTTPS',
              :Protocol => 'HTTPS',
              :PolicyNames => [ 'PublicELBCookieStickinessPolicy' ],
              :SSLCertificateId => ref('SSLCertificateARN'),
          },
      ],
      :HealthCheck => {
          :Target => { :'Fn::If' => [ 'BackendSSLCon', 'HTTPS:443/humans.txt', 'HTTP:80/humans.txt' ] },
          :HealthyThreshold => '2',
          :UnhealthyThreshold => '10',
          :Interval => '90',
          :Timeout => '60',
      },
      :Tags => [
          { :Key => 'Name', :Value => 'Chef-ELB' },
      ],
  }

  resource 'SecondaryElasticLoadBalancer', :Type => 'AWS::ElasticLoadBalancing::LoadBalancer', :Condition => 'SecondaryDomainCon', :Properties => {
      :Subnets => [
          ref('SubnetA'),
          ref('SubnetB'),
          ref('SubnetC'),
      ],
      :SecurityGroups => [ ref('LoadBalancerSecurityGroup') ],
      :LBCookieStickinessPolicy => [
          { :PolicyName => 'PublicELBCookieStickinessPolicy', :CookieExpirationPeriod => '3600' },
      ],
      :Listeners => [
          {
              :InstancePort => { :'Fn::If' => [ 'BackendSSLCon', '443', '80' ] },
              :LoadBalancerPort => '443',
              :InstanceProtocol => 'HTTPS',
              :Protocol => 'HTTPS',
              :PolicyNames => [ 'PublicELBCookieStickinessPolicy' ],
              :SSLCertificateId => ref('SecondarySSLCertificateARN'),
          },
      ],
      :HealthCheck => {
          :Target => { :'Fn::If' => [ 'BackendSSLCon', 'HTTPS:443/humans.txt', 'HTTP:80/humans.txt' ] },
          :HealthyThreshold => '2',
          :UnhealthyThreshold => '10',
          :Interval => '90',
          :Timeout => '60',
      },
      :Tags => [
          { :Key => 'Name', :Value => 'Chef-Secondary-ELB' },
      ],
  }

  resource 'ChefDNS', :Type => 'AWS::Route53::RecordSetGroup', :Properties => {
      :HostedZoneName => join('', ref('HostedZone'), '.'),
      :Comment => 'Zone apex alias targeted to myELB LoadBalancer.',
      :RecordSets => [
          {
              :Name => join('', ref('ChefSubdomain'), '.', ref('HostedZone'), '.'),
              :Type => 'A',
              :AliasTarget => {
                  :HostedZoneId => get_att('PrimaryElasticLoadBalancer', 'CanonicalHostedZoneNameID'),
                  :DNSName => get_att('PrimaryElasticLoadBalancer', 'CanonicalHostedZoneName'),
              },
          },
      ],
  }

  resource 'SecondaryChefDNS', :Type => 'AWS::Route53::RecordSetGroup', :Properties => {
      :HostedZoneName => join('', ref('HostedZone'), '.'),
      :Comment => 'Zone apex alias targeted to myELB LoadBalancer.',
      :RecordSets => [
          {
              :Name => join('', ref('ChefSubdomain'), '-secondary', '.', ref('HostedZone'), '.'),
              :Type => 'A',
              :AliasTarget => {
                  :HostedZoneId => get_att('SecondaryElasticLoadBalancer', 'CanonicalHostedZoneNameID'),
                  :DNSName => get_att('SecondaryElasticLoadBalancer', 'CanonicalHostedZoneName'),
              },
          },
      ],
  }

  resource 'FrontendSecurityGroup', :Type => 'AWS::EC2::SecurityGroup', :Properties => {
      :GroupDescription => 'Setup Ingress/Egress for Chef Frontend',
      :VpcId => ref('VPC'),
      :SecurityGroupIngress => [
          {
              :IpProtocol => 'tcp',
              :FromPort => '80',
              :ToPort => '80',
              :SourceSecurityGroupId => ref('LoadBalancerSecurityGroup'),
          },
          {
              :IpProtocol => 'tcp',
              :FromPort => '443',
              :ToPort => '443',
              :SourceSecurityGroupId => ref('LoadBalancerSecurityGroup'),
          },
          {
              :IpProtocol => 'tcp',
              :FromPort => '443',
              :ToPort => '9090',
              :SourceSecurityGroupId => ref('LoadBalancerSecurityGroup'),
          },
          {
              :IpProtocol => 'tcp',
              :FromPort => '80',
              :ToPort => '9090',
              :SourceSecurityGroupId => ref('LoadBalancerSecurityGroup'),
          },
          {
              :IpProtocol => 'tcp',
              :FromPort => '22',
              :ToPort => '22',
              :SourceSecurityGroupId => ref('SSHSecurityGroup'),
          },
      ],
      :SecurityGroupEgress => [
          { :IpProtocol => 'tcp', :FromPort => '0', :ToPort => '65535', :CidrIp => '0.0.0.0/0' },
      ],
      :Tags => [
          { :Key => 'Name', :Value => 'ChefFrontend-Security-Group' },
      ],
  }

  resource 'AutoScaleGroup', :Type => 'AWS::AutoScaling::AutoScalingGroup', :Condition => 'SingleDomainCon', :Properties => {
      :AvailabilityZones => get_azs,
      :VPCZoneIdentifier => [
          ref('SubnetA'),
          ref('SubnetB'),
          ref('SubnetC'),
      ],
      :LaunchConfigurationName => ref('ServerLaunchConfig'),
      :MinSize => '2',
      :MaxSize => '3',
      :LoadBalancerNames => [
          ref('PrimaryElasticLoadBalancer'),
          ref('SecondaryElasticLoadBalancer'),
      ],
      :Tags => [
          { :Key => 'Name', :Value => 'Chef-Scale-Group', :PropagateAtLaunch => 'true' },
      ],
  }

  resource 'SecondaryAutoScaleGroup', :Type => 'AWS::AutoScaling::AutoScalingGroup', :Condition => 'SecondaryDomainCon', :Properties => {
      :AvailabilityZones => get_azs,
      :VPCZoneIdentifier => [
          ref('SubnetA'),
          ref('SubnetB'),
          ref('SubnetC'),
      ],
      :LaunchConfigurationName => ref('ServerLaunchConfig'),
      :MinSize => '1',
      :DesiredCapacity => '2',
      :MaxSize => '3',
      :LoadBalancerNames => [
          ref('PrimaryElasticLoadBalancer'),
          ref('SecondaryElasticLoadBalancer'),
      ],
      :Tags => [
          { :Key => 'Name', :Value => 'Chef-Scale-Group', :PropagateAtLaunch => 'true' },
      ],
  }

  resource 'ServerLaunchConfig', :Type => 'AWS::AutoScaling::LaunchConfiguration', :Properties => {
      :ImageId => find_in_map('AWSRegionArch2AMI', aws_region, find_in_map('AWSInstanceType2Arch', ref('InstanceType'), 'Arch')),
      :AssociatePublicIpAddress => 'true',
      :InstanceType => ref('InstanceType'),
      :SecurityGroups => [
          ref('FrontendSecurityGroup'),
          ref('SSHSecurityGroup'),
      ],
      :KeyName => ref('KeyName'),
      :BlockDeviceMappings => [
          {
              :DeviceName => '/dev/sda1',
              :Ebs => { :VolumeSize => '15' },
          },
      ],
      :IamInstanceProfile => ref('ChefInstanceProfile'),
      :UserData => base64(
          join('',
               "#!/bin/bash -xev\n",
               "apt-get update && apt-get -y upgrade\n",
               "apt-get install -y wget curl python-setuptools python-pip git\n",
               "# Helper function to set wait timer\n",
               "function error_exit\n",
               "{\n",
               '  /usr/local/bin/cfn-signal -e 1 -r "$1" \'',
               ref('WaitHandle'),
               "'\n",
               "  exit 1\n",
               " }\n",
               "export -f error_exit\n",
               'curl -Sl ',
               ref('UserDataScript'),
               " -o /tmp/userdata.sh\n",
               "chmod +x /tmp/userdata.sh\n",
               'export REGION=\'',
               aws_region,
               "'\n",
               'export IAM_ROLE=\'',
               ref('ChefRole'),
               "'\n",
               'export DOMAIN=\'',
               ref('HostedZone'),
               "'\n",
               'export SECONDARY_DOMAIN=\'',
               ref('SecondaryDomain'),
               "'\n",
               'export SUBDOMAIN=\'',
               ref('ChefSubdomain'),
               "'\n",
               'export BUCKET=\'',
               {
                   :'Fn::If' => [
                       'CreateChefBucket',
                       ref('ChefBucket'),
                       ref('BucketName'),
                   ],
               },
               "'\n",
               'export DB_USER=\'',
               ref('DBUser'),
               "'\n",
               'export DB_PASSWORD=\'',
               ref('DBPassword'),
               "'\n",
               'export DB_PORT=\'',
               ref('DBPort'),
               "'\n",
               'export DB_URL=\'',
               ref('DBURL'),
               "'\n",
               'export SEARCH_URL=\'',
               ref('ElasticSearchURL'),
               "'\n",
               'export COOKBOOK=\'',
               ref('Cookbook'),
               "'\n",
               'export COOKBOOK_GIT=\'',
               ref('CookbookGit'),
               "'\n",
               'export COOKBOOK_BRANCH=\'',
               ref('CookbookGitBranch'),
               "'\n",
               'export ENABLE_SSL=\'',
               ref('BackendSSL'),
               "'\n",
               'export BACKUP_ENABLE=\'',
               ref('BackupEnable'),
               "'\n",
               'export EXISTING_INSTALL=\'',
               ref('ExistingInstall'),
               "'\n",
               'export CHEFDIR=\'',
               ref('ChefDir'),
               "'\n",
               'export S3DIR=\'',
               ref('S3Dir'),
               "'\n",
               'export SIGNUP_DISABLE=\'',
               ref('SignupDisable'),
               "'\n",
               'export SUPPORT_EMAIL=\'',
               ref('SupportEmail'),
               "'\n",
               "set +xv\n",
               'export NR_LICENSE=\'',
               ref('NewRelicLicense'),
               "'\n",
               'export NR_APPNAME=\'',
               ref('NewRelicAppName'),
               "'\n",
               'export NR_ENABLE=\'',
               ref('NewRelicEnable'),
               "'\n",
               'export SUMO_ENABLE=\'',
               ref('SumologicEnable'),
               "'\n",
               'export SUMO_ACCESS_ID=\'',
               ref('SumologicAccessID'),
               "'\n",
               'export SUMO_ACCESS_KEY=\'',
               ref('SumologicAccessKey'),
               "'\n",
               'export SUMO_PASSWORD=\'',
               ref('SumologicPassword'),
               "'\n",
               'export MAIL_CREDS=\'',
               ref('MailCreds'),
               "'\n",
               "set -xv\n",
               'export MAIL_HOST=\'',
               ref('MailHost'),
               "'\n",
               'export MAIL_PORT=\'',
               ref('MailPort'),
               "'\n",
               'export LICENSE_COUNT=\'',
               ref('LicenseCount'),
               "'\n",
               "/tmp/userdata.sh\n",
               "# All is well so signal success and let CF know wait function is complete\n",
               '/usr/local/bin/cfn-signal -e 0 -r "Server setup complete" \'',
               ref('WaitHandle'),
               "'\n",
               'rm -f /tmp/userdata.sh',
          )
      ),
  }

  resource 'WaitHandle', :Type => 'AWS::CloudFormation::WaitConditionHandle'

  resource 'WaitCondition', :Type => 'AWS::CloudFormation::WaitCondition', :DependsOn => 'ServerLaunchConfig', :Properties => {
      :Handle => ref('WaitHandle'),
      :Timeout => '2300',
  }

end.exec!
