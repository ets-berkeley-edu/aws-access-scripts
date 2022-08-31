#!/usr/bin/env bash

# In order to use this script you need to do several things.
# 1.  You must have the aws commandline client installed and in your PATH.  If you use homebrew:  brew install awscli
# https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
#
# 2.  You must have the aws session-manager-plugin installed.  If you use homebrew:  brew install session-manager-plugin
# https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html#install-plugin-macos
#
# 3.  If using tunneling or sftp, You must have a private key for the host you wish to connect to.
# Check your lastpass vault or contact operations.
#
# 4.  Lastly you need to make sure your AWS credentials have been exported to your environment.
# https://ucberkeley.awsapps.com/start

unset instance_id
unset aws_user
unset instance_name
unset aws_list
unset aws_sftp
unset private_key
unset tunnel

aws_sftp="false"
aws_list="false"
region="us-west-2"

while getopts ":i:u:n:r:k:t:lf" opts; do
  case $opts in
    f) aws_sftp="true" ;;
    i) instance_id=${OPTARG} ;;
    k) private_key=${OPTARG} ;;
    l) aws_list="true" ;;
    n) instance_name=${OPTARG} ;;
    r) region=${OPTARG} ;;
    t) tunnel=${OPTARG} ;;
    u) aws_user=${OPTARG} ;;
    *)
       echo "Usage: aws-ssh [-l]|[-f]|[-t SourcePort:RemoteHost:RemotePort] [-i InstanceId]|[-n InstanceName] [-k PrivateKey] [-u username] [-r region]" >&2
       echo "  -l Lists ec2 instances, always works" >&2
       echo "  -f Secure FTP, must also specify -u and -k" >&2
       echo "  -t Tunnel, ex: 8000:localhost:80, must also specify -u and -k" >&2
       echo "" >&2
       echo "  -i Specify InstanceId, always works" >&2
       echo "  -n Specify InstanceName, must be unique.  Use -i if the InstanceName is not unique." >&2
       echo "" >&2
       echo "  -k Specify file containing ssh private key for ec2 instance" >&2
       echo "  -u Specify user to login as, typical values are ubuntu or ec2-user" >&2
       echo "  -r Specify region, defaults to us-west-2" >&2
       echo "" >&2
       echo "If you only specify -i or -n, the script will attempt to open a shell via the session manager."
       echo "" >&2
       exit 1
  esac
done

# List all running instances
if [ ${aws_list} == "true" ]; then
  aws ec2 describe-instances --region ${region} --query "Reservations[].Instances[].{InstanceName:Tags[?Key=='Name']|[0].Value,InstanceId:InstanceId,State:State.Name}" --filter "Name=instance-state-name,Values=running" --output table
  exit 0
fi

# You cannot sftp and tunnel at the same time
if [ ! -z ${tunnel} ] && [ ${aws_sftp} == "true" ]; then
  echo "You may specify -f (sftp) or -t (tunnel), but not both!" >&2
  exit 1
fi

# If you're not listing instances, you need to specify one by id or by name
if [ -z ${instance_id} ] && [ -z ${instance_name} ]; then
  echo "You must specify an InstanceId (-i) or an InstanceName (-n).  Use -l to get a list!" >&2
  exit 1
fi

# If an id wasn't specified, that means we have the name.  Use it to get the id.
if [ -z ${instance_id} ]; then
  instance_id=$(aws ec2 describe-instances --region ${region} --filter "Name=tag:Name,Values=${instance_name}" "Name=instance-state-name,Values=running" --query "Reservations[].Instances[].InstanceId[]" --output text)
  
  if [[ ${instance_id} =~ [[:space:]] ]]; then
    echo "${instance_name} matches multiple instances, use -l to get a list and then specify an InstanceId with -i!" >&2
    exit 1
  fi
fi

# SFTP was chosen, check to make sure -k and -u were specified and attempt it
if [ ${aws_sftp} == "true" ]; then
  if [ -z ${private_key} ] || [ ! -f ${private_key} ]; then
    echo "You must specify a valid private key with -k if you wish to sftp!" >&2
    exit 1
  elif [ -z ${aws_user} ]; then
    echo "You must specify a user with -u if you wish to sftp!" >&2
    exit 1
  else
    sftp -oProxyCommand="aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters 'portNumber=%p'" -oIdentityFile=${private_key} ${aws_user}@${instance_id}
  fi
# Tunnel was chosen, check to make sure -k and -u were specified and attempt it
elif [ ! -z ${tunnel} ]; then
  if [ -z ${private_key} ] || [ ! -f ${private_key} ]; then
    echo "You must specify a valid private key with -k if you wish to tunnel!" >&2
    exit 1
  elif [ -z ${aws_user} ]; then
    echo "You must specify a user with -u if you wish to tunnel!" >&2
    exit 1
  else
    ssh -o ProxyCommand="aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters 'portNumber=%p'" -i ${private_key} ${aws_user}@${instance_id} -L ${tunnel}
  fi
# Otherwise try to open a shell    
else
  # If ssh arguments are missing, attempt the session manager
  if [ -z ${aws_user} ] || [ -z ${private_key} ] || [ ! -f ${private_key} ]; then
    aws ssm start-session --region ${region} --target ${instance_id}
  # Otherwise attempt ssh
  else
    ssh -o ProxyCommand="aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters 'portNumber=%p'" -i ${private_key} ${aws_user}@${instance_id}
  fi
fi