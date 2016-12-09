# Backendless Chef Stack

Cloudformation Templates to build out a complete Backendless Chef Configuration

**Note:** No longer requires a Cookbook to build.

## Info

-   Builds out customized Chef Server build out without any backends to zone lock your setup
-   Built to utilize Ubuntu Xenial
-   Allows you to choose versions to install on Chef-Server, Manage, and Reporting (Limited to Xenial Supported versions)
-   Builds out a RDS PostgreSQL Database, Version: 9.5.4
-   Builds out AWS Elasticsearch Domain w/ 2 Nodes, Version: 2.3
-   Offers [Backup Solution](#backup-options)

## Diagram

![Alt text](backendless_chef.png?raw=true "Overview Diagram")

## Requirements

-   Existing VPC
    -   IP Scheme of 172.33.0.0/16 or modify template to support whichever
    -   SSH Security Group (Will lookup existing groups in AWS, make sure one exists)
-   Route53 Hosted Domain/Zone
-   Existing SSL Certificate (Loaded into AWS and provide in the params below)

## Usage

### VPC Setup

Add some VPC Setup Info

### SSL Setup

To simplify the setup only the ELB (Public Side) is setup with SSL.

To setup a SSL Cert in AWS Follow this [Guide](#insert_a_url)

`aws iam get-server-certificate --server-certificate-name`

### Blue/Green Deployment

Data about how the subdomains work and using it to do blue/green deployments

#### Subnet Switching

Explain how subnets are swapped based on subdomain

### Restore Options

Data about restore script and link to specific code

Data about building from DB Snapshots

### Backup Options

Data about backup script and link to specific code

## Contributing

## Credits

Special Thanks to [Irving Popovetsky](https://github.com/irvingpop) for answering all my questions and being patient with me!

## License
