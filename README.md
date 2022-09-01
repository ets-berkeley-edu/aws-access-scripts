# aws-access-scripts
Scripts for accessing aws via ssh and/or the session manager. 

## Installation
I highly recommend using homebrew if you do not already.  It provides the ability to install, upgrade, and manage lots of different software packages:  https://brew.sh/

In order to use these scripts, do the following:

 1. Clone this repo on your workstation so you have the aws-ssh.sh script.
 2. Install the AWS command line client and make sure it's available in your PATH.  
If you use homebrew:  `brew install awscli` 
Otherwise refer to the official installation docs:  https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
 3. Install the AWS session-manager-plugin.
 If you use homebrew:  `brew install session-manager-plugin`
 Otherwise refer to the official installation docs: https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html#install-plugin-macos
 4. Export your AWS credentials to your local shell environment:  https://ucberkeley.awsapps.com/start
 5. If you plan to use tunneling or sftp, you will need the appropriate ssh private key and know which user you wish to connect as.  This can typically be found in LastPass.  Contact operations if you need assistance.

## Usage
Once you've met the installation dependencies for the script you can use it to list ec2 instances, open a shell, transfer files via sftp, or tunnel via ssh.

The script takes the following arguments:

 - -l list ec2 instances
 - -f secure FTP, must also specify -u and -k
 - -t sourcePort:remoteHost:remotePort, instantiate a tunnel, must also specify -u and -k, e.g. `-t 5432:dbserver.host:5432`
 - -i InstanceId, specify ec2 instance by InstanceID (useful if InstanceName is not unique), e.g. `-i i-12345678901234567`
 - -n InstanceName, specify ec2 instance by InstanceName, e.g. `-n demo-qa`
 - -k specify file containing ssh private key, e.g. `-k path_to_key`
 - -u specify user to login as (typically ubuntu or ec2-user), e.g. `-u ubuntu`
 - -r specify region (defaults to us-west-2 if not specified), e.g. `-r us-west-1`
### List 
    MacBook-Pro:~ felder$ ./aws-ssh.sh -l
    -------------------------------------------------------
    |                  DescribeInstances                  |
    +----------------------+-------------------+----------+
    |      InstanceId      |   InstanceName    |  State   |
    +----------------------+-------------------+----------+
    |  i-12345678901234567 |  demo-qa          |  running |
    |  i-76543210987654321 |  demo-prod        |  running |
    +----------------------+-------------------+----------+
### Open a shell via session manager by InstanceName
    MacBook-Pro:~ felder$ ./aws-ssh.sh -n demo-qa
    Starting session with SessionId: user@berkeley.edu-1234512345123
    $
### Open a shell via session manager by InstanceId
    MacBook-Pro:~ felder$ ./aws-ssh.sh -i i-12345678901234567
    Starting session with SessionId: user@berkeley.edu-1234512345123
    $
### Open a shell via SSH (using InstanceName)
    MacBook-Pro:~ felder$ ./aws-ssh.sh -n demo-qa -k ~/.ssh/demo-qa -u ubuntu
    Warning: Permanently added 'i-1234512345123' (ED25519) to the list of known hosts.
    Welcome to Ubuntu 20.04.4 LTS (GNU/Linux 5.15.0-1017-aws x86_64) 
    Last login: Thu Sep  1 13:32:07 2022 from 127.0.0.1
    ubuntu@demo-qa:~$
### Transfer files via SFTP (using InstanceName)
    MacBook-Pro:~ felder$ ./aws-ssh.sh -n demo-qa -k ~/.ssh/demo-qa -u ubuntu -f
    Warning: Permanently added 'i-12345678901234567' (ED25519) to the list of known hosts.
    Connected to i-12345678901234567.
    sftp>
###  SSH Tunnel (using InstanceName)
    MacBook-Pro:~ felder$ ./aws-ssh.sh -n demo-qa -k ~/.ssh/demo-qa -u ubuntu -t 5432:dbserver.host:5432
    Warning: Permanently added 'i-1234512345123' (ED25519) to the list of known hosts.
    Welcome to Ubuntu 20.04.4 LTS (GNU/Linux 5.15.0-1017-aws x86_64) 
    Last login: Thu Sep  1 13:32:07 2022 from 127.0.0.1
    ubuntu@demo-qa:~$
From another local terminal window:

    MacBook-Pro:~ felder$ psql -h localhost -U dbuser -d dbname
    Password for user dbuser:
    psql (14.5, server 14.3)
    SSL connection (protocol: TLSv1.2, cipher: ECDHE-RSA-AES256-GCM-SHA384, bits: 256, compression: off)
    Type "help" for help.
    
    dbname=>




