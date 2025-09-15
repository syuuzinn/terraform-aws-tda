#!/bin/bash

projectName="basecamp-step1"
vpcCider="10.0.0.0/16"
public1Cider="10.0.0.0/24"
public1AZ="ap-northeast-1a"
public2Cider="10.0.1.0/24"
public2AZ="ap-northeast-1c"
private1Cider="10.0.10.0/24"
private1AZ="ap-northeast-1a"
private2Cider="10.0.11.0/24"
private2AZ="ap-northeast-1c"

instanceType="t3.micro"
volumeType="gp3"
Encrypted="true"
ebsSize=8

DBType="db.t3.micro"
DBEngine="mysql"
DBStorage=20
DBStorageType="gp2"
EngineVersion=8

empty_check ()  {
    if [ -z "$1" ]; then
        echo -e "$3"
        exit 1
    fi
    echo  "$2: OK"
    return 0
}
empty_check_no_echo ()  {
    if [ -z "$1" ]; then
        echo -e "$2"
        exit 1
    fi
    return 0
}

# NW のチェック

# VPC
vpcId=`aws ec2 describe-vpcs --filters \
            "Name=tag:Name,Values=$projectName-vpc" |  \
            jq -r --arg Cider $vpcCider \
            '.Vpcs[]| select(.CidrBlock == $Cider) |.VpcId'`

empty_check_no_echo "$vpcId" "VPCが正しく作成されていません。\nパラメータをご確認ください"

EnableDnsHostnames=`aws ec2 describe-vpc-attribute --attribute enableDnsHostnames \
            --vpc-id $vpcId --query "EnableDnsHostnames.Value"` 

empty_check "$EnableDnsHostnames" "VPC" "VPCのDNS ホスト名の設定が正しくありません。\nパラメータをご確認ください"


# IGW
InternetGatewayId=`aws ec2 describe-internet-gateways --filters \
        "Name=tag:Name,Values=$projectName-igw" | \
        jq -r --arg vpc $vpcId \
        '.InternetGateways[] | select(.Attachments[0].State == "available" and .Attachments[0].VpcId == $vpc ) | .InternetGatewayId'`

empty_check "$InternetGatewayId" "InternetGateway" "Internet Gatewayが正しく設定されていません。\nパラメータをご確認ください"


# サブネット
Public1Id=`aws ec2 describe-subnets --filters \
        "Name=tag:Name,Values=$projectName-public1" | \
        jq -r --arg Cider $public1Cider --arg vpc $vpcId --arg az $public1AZ \
        '.Subnets[] | select(.CidrBlock == $Cider and .VpcId == $vpc and .AvailabilityZone == $az) | .SubnetId'` 
empty_check "$Public1Id" "Public Subnet(${public1AZ})" "パブリックサブネット(${public1AZ})が正しく設定されていません。\nパラメータをご確認ください"
Public2Id=`aws ec2 describe-subnets --filters \
        "Name=tag:Name,Values=$projectName-public2" | \
        jq -r --arg Cider $public2Cider --arg vpc $vpcId --arg az $public2AZ \
        '.Subnets[] | select(.CidrBlock == $Cider and .VpcId == $vpc and .AvailabilityZone == $az) | .SubnetId'`
empty_check "$Public2Id" "Public Subnet(${public2AZ})" "パブリックサブネット(${public2AZ})が正しく設定されていません。\nパラメータをご確認ください"
Private1Id=`aws ec2 describe-subnets --filters \
        "Name=tag:Name,Values=$projectName-private1" | \
        jq -r --arg Cider $private1Cider --arg vpc $vpcId --arg az $private1AZ \
        '.Subnets[] | select(.CidrBlock == $Cider and .VpcId == $vpc and .AvailabilityZone == $az) | .SubnetId'`
empty_check "$Private1Id" "Private Subnet(${private1AZ})" "パブリックサブネット(${private1AZ})が正しく設定されていません。\nパラメータをご確認ください"
Private2Id=`aws ec2 describe-subnets --filters \
        "Name=tag:Name,Values=$projectName-private2" | \
        jq -r --arg Cider $private2Cider --arg vpc $vpcId --arg az $private2AZ \
        '.Subnets[] | select(.CidrBlock == $Cider and .VpcId == $vpc and .AvailabilityZone == $az) | .SubnetId'`
empty_check "$Private2Id" "Private Subnet(${private2AZ})" "パブリックサブネット(${private2AZ})が正しく設定されていません。\nパラメータをご確認ください"

# ルートテーブル
publicRoute=`aws ec2 describe-route-tables  --filters \
        "Name=association.subnet-id,Values=$Public1Id" \
        "Name=association.subnet-id,Values=$Public2Id" \
        "Name=tag:Name,Values=$projectName-public-rtb" \
        "Name=vpc-id,Values=$vpcId" | \
        jq -r '.RouteTables[]'`
empty_check_no_echo "$publicRoute"  "ルートテーブルが正しく設定されていません。\nパラメータをご確認ください"

localCheck=`echo $publicRoute | jq -r '.Routes[] | select(.DestinationCidrBlock == "10.0.0.0/16" and .GatewayId == "local" )'`
empty_check_no_echo "$localCheck" "ルートテーブルが正しく設定されていません。\nパラメータをご確認ください"

internetCheck=`echo $publicRoute | \
        jq -r --arg igw $InternetGatewayId \
        '.Routes[] | select(.DestinationCidrBlock == "0.0.0.0/0" and .GatewayId == $igw )'`
empty_check_no_echo "$internetCheck" "ルートテーブルが正しく設定されていません。\nパラメータをご確認ください"

privateAssociationNum=`aws ec2 describe-route-tables --filters \
            "Name=association.subnet-id,Values=$Private1Id,$Private2Id" \
            "Name=vpc-id,Values=$vpcId" | \
            jq -r '.RouteTables| length'`
empty_check_no_echo "$privateAssociationNum"  "ルートテーブルが正しく設定されていません。\nパラメータをご確認ください"

mainCheck=`aws ec2 describe-route-tables --filters \
            "Name=association.main,Values=true" \
            "Name=vpc-id,Values=$vpcId" | \
            jq -r --arg Cider $vpcCider \
            '.RouteTables[] | .Routes[] | select(.DestinationCidrBlock == $Cider and .GatewayId == "local" )'`
empty_check "$mainCheck" "ルートテーブル" "ルートテーブルが正しく設定されていません。\nパラメータをご確認ください"

#セキュリティグループ
albSGId=`aws ec2 describe-security-groups --filters \
        "Name=group-name,Values=$projectName-alb-sg" \
        "Name=vpc-id,Values=$vpcId" | \
        jq -r --arg Cider $vpcCider \
        '.SecurityGroups[] | select( .IpPermissions == []  and .IpPermissionsEgress[].IpProtocol == "-1" and .IpPermissionsEgress[].IpRanges[].CidrIp == "0.0.0.0/0" ) | .GroupId'`
empty_check "$albSGId" "セキュリティグループ($projectName-alb-sg)" "セキュリティグループ($projectName-alb-sg)が正しく設定されていません。\nパラメータをご確認ください"

ec2SGId=`aws ec2 describe-security-groups --filters \
        "Name=group-name,Values=$projectName-ec2-sg" \
        "Name=vpc-id,Values=$vpcId" | \
        jq -r --arg groupId $albSGId \
        '.SecurityGroups[] | select( .IpPermissions[].IpProtocol == "tcp" and .IpPermissions[].FromPort == 80 and .IpPermissions[].UserIdGroupPairs[].GroupId == $groupId and .IpPermissionsEgress[].IpProtocol == "-1" and .IpPermissionsEgress[].IpRanges[].CidrIp == "0.0.0.0/0" ) | .GroupId'`
empty_check "$ec2SGId" "セキュリティグループ($projectName-ec2-sg)" "セキュリティグループ($projectName-ec2-sg)が正しく設定されていません。\nパラメータをご確認ください"

rdsSGId=`aws ec2 describe-security-groups --filters \
        "Name=group-name,Values=$projectName-rds-sg" \
        "Name=vpc-id,Values=$vpcId" | \
        jq -r --arg groupId $ec2SGId \
        '.SecurityGroups[] | select( .IpPermissions[].IpProtocol == "tcp" and .IpPermissions[].FromPort == 3306 and .IpPermissions[].UserIdGroupPairs[].GroupId == $groupId and .IpPermissionsEgress[].IpProtocol == "-1" and .IpPermissionsEgress[].IpRanges[].CidrIp == "0.0.0.0/0" ) | .GroupId'`
empty_check "$rdsSGId" "セキュリティグループ($projectName-rds-sg)" "セキュリティグループ($projectName-rds-sg)が正しく設定されていません。\nパラメータをご確認ください"

# IAM
statementCheck=`aws iam get-role --role-name "$projectName-ec2-iam-role" | \
     jq -r 'select( .Role.AssumeRolePolicyDocument.Statement[].Effect == "Allow" and .Role.AssumeRolePolicyDocument.Statement[].Principal.Service == "ec2.amazonaws.com" and .Role.AssumeRolePolicyDocument.Statement[].Action == "sts:AssumeRole" )'`
empty_check_no_echo "$statementCheck"  "IAMロールが正しく作成されていません。\nパラメータをご確認ください"

attchCkeck=`aws iam list-attached-role-policies --role-name "$projectName-ec2-iam-role" |
    jq -r 'select( .AttachedPolicies[].PolicyArn == "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore")'`
empty_check "$attchCkeck" "IAM Role" "IAMロールが正しく作成されていません。\nパラメータをご確認ください"

# EC2
ec2Info1=`aws ec2 describe-instances --filters \
    "Name=tag:Name,Values=$projectName-ec2-1" | \
    jq -r \
    --arg instanceType $instanceType\
    --arg SubnetId $Public1Id \
    --arg VpcId $vpcId \
    --arg GroupId $ec2SGId \
    '.Reservations[0].Instances[0] | select( .State.Name == "running" and .InstanceType == $instanceType and .PublicIpAddress != null and .SubnetId == $SubnetId and .VpcId == $VpcId and .NetworkInterfaces[].Groups[].GroupId == $GroupId) '`
empty_check_no_echo "$ec2Info1"  "EC2($projectName-ec2-1)が正しく作成されていません。\nパラメータをご確認ください"

ec2AmiId1=`echo $ec2Info1 | jq -r '.ImageId'`
ami1=`aws ec2 describe-images --image-ids "$ec2AmiId1" --filters 'Name=name,Values=amzn2-ami*'`
empty_check_no_echo "$ami1"  "EC2($projectName-ec2-1)のAMIが正しく設定されていません。\nパラメータをご確認ください"

EBS1Id=`echo $ec2Info1 | jq -r '.BlockDeviceMappings[0].Ebs.VolumeId'`
ebs1Check=`aws ec2 describe-volumes --volume-ids $EBS1Id | \
    jq -r --arg size $ebsSize \
    --arg vType $volumeType \
    --arg encrypt $Encrypted \
    '.Volumes[] | select( (.Size|tostring) == $size and .VolumeType == $vType and (.Encrypted|tostring) == $encrypt) '`

empty_check_no_echo "$ebs1Check"  "EC2($projectName-ec2-1)のEBSが正しく設定されていません。\nパラメータをご確認ください"

InstanceProfile1ARN=`echo $ec2Info1 | jq -r '.IamInstanceProfile.Arn'`
InstanceProfile1Name=`echo $InstanceProfile1ARN | sed -E 's/^.*instance-profile\///'`
InstanceProfile1Check=`aws iam get-instance-profile \
    --instance-profile-name $InstanceProfile1Name |\
    jq -r --arg role "$projectName-ec2-iam-role" \
    'select( .InstanceProfile.Roles[0].RoleName == $role)'`
empty_check "$InstanceProfile1Check" "EC2($projectName-ec2-1)" "EC2($projectName-ec2-1)のIAM Roleが正しく設定されていません。\nパラメータをご確認ください"

ec2Info2=`aws ec2 describe-instances --filters \
    "Name=tag:Name,Values=$projectName-ec2-2" | \
    jq -r \
    --arg instanceType $instanceType\
    --arg SubnetId $Public2Id \
    --arg VpcId $vpcId \
    --arg GroupId $ec2SGId \
    '.Reservations[0].Instances[0] | select( .State.Name == "running" and .InstanceType == $instanceType and .PublicIpAddress != null and .SubnetId == $SubnetId and .VpcId == $VpcId and .NetworkInterfaces[].Groups[].GroupId == $GroupId) '`
empty_check_no_echo "$ec2Info2"  "EC2($projectName-ec2-2)が正しく作成されていません。\nパラメータをご確認ください"

ec2AmiId2=`echo $ec2Info2 | jq -r '.ImageId'`
ami2=`aws ec2 describe-images --image-ids "$ec2AmiId2" --filters 'Name=name,Values=amzn2-ami*'`
empty_check_no_echo "$ami2"  "EC2($projectName-ec2-2)のAMIが正しく設定されていません。\nパラメータをご確認ください"

EBS2Id=`echo $ec2Info2 | jq -r '.BlockDeviceMappings[0].Ebs.VolumeId'`
ebs2Check=`aws ec2 describe-volumes --volume-ids $EBS2Id | \
    jq -r --arg size $ebsSize \
    --arg vType $volumeType \
    --arg encrypt $Encrypted \
    '.Volumes[] | select( (.Size|tostring) == $size and .VolumeType == $vType and (.Encrypted|tostring) == $encrypt)'`
empty_check_no_echo "$ebs2Check"  "EC2($projectName-ec2-2)のEBSが正しく設定されていません。\nパラメータをご確認ください"

InstanceProfile2ARN=`echo $ec2Info2 | jq -r '.IamInstanceProfile.Arn'`
InstanceProfile2Name=`echo $InstanceProfile2ARN | sed -E 's/^.*instance-profile\///'`
InstanceProfile2Chech=`aws iam get-instance-profile \
    --instance-profile-name $InstanceProfile2Name |\
    jq -r --arg role "$projectName-ec2-iam-role" \
    'select( .InstanceProfile.Roles[0].RoleName == $role)'`
empty_check "$InstanceProfile2Chech" "EC2($projectName-ec2-2)" "EC2($projectName-ec2-2)のIAM Roleが正しく設定されていません。\nパラメータをご確認ください"

# ALB
tgARN=`aws elbv2 describe-target-groups --names "$projectName-tg" | \
        jq -r --arg vpcId $vpcId \
        '.TargetGroups[0] | select( .Protocol == "HTTP" and .Port == 80 and .VpcId == $vpcId )'|
        jq -r \
        'select(.HealthCheckProtocol == "HTTP" and .HealthCheckPort == "traffic-port" and .HealthCheckEnabled == true and .HealthCheckIntervalSeconds == 30 and .HealthCheckTimeoutSeconds ==5 and .HealthyThresholdCount == 5 and .UnhealthyThresholdCount  == 2 and .HealthCheckPath == "/" and .Matcher.HttpCode == "200" )|.TargetGroupArn'`
empty_check_no_echo "$tgARN"  "ターゲットグループが正しく設定されていません。\nパラメータをご確認ください"

InstanceId1=`echo $ec2Info1 | jq -r '.InstanceId'`
InstanceId2=`echo $ec2Info2 | jq -r '.InstanceId'`

InstanceAttchCheck=`aws elbv2 describe-target-health --target-group-arn $tgARN |
        jq -r --arg id1 $InstanceId1 \
        --arg id2 $InstanceId2 \
        'select( .TargetHealthDescriptions[].Target.Id == $id1 and .TargetHealthDescriptions[].Target.Id == $id2)' `
empty_check "$tgARN" "TargetGeoup" "ターゲットグループが正しく設定されていません。\nパラメータをご確認ください"

albCheck=`aws elbv2 describe-load-balancers --names "$projectName-alb" |\
        jq -r --arg subnet1 $Public1Id \
        --arg subnet2 $Public2Id \
        --arg sgId $albSGId \
        '.LoadBalancers[0]| select(.Scheme=="internet-facing" and .Type=="application" and .AvailabilityZones[].SubnetId == $subnet1 and .AvailabilityZones[].SubnetId == $subnet2 and .SecurityGroups[] == $sgId and .IpAddressType=="ipv4")'`
empty_check "$albCheck" "ALB" "ロードバランサが正しく作成されていません。\nパラメータをご確認ください"


# RDS
version=`aws rds describe-db-instances --db-instance-identifier "$projectName-rds" | \
        jq -r --arg vpcId $vpcId \
            --arg subnet1 $Private1Id \
            --arg subnet2 $Private2Id \
            --arg dbtype $DBType \
            --arg dbengine $DBEngine \
            --arg storage $DBStorage \
            --arg sttype $DBStorageType\
            --arg sgId $rdsSGId \
            --arg sbname "$projectName-rds-subnet-group" \
            '.DBInstances[] | select(.DBInstanceClass==$dbtype and .DBInstanceStatus=="available" and .Engine==$dbengine and .Endpoint.Port == 3306 and (.AllocatedStorage|tostring)==$storage and .VpcSecurityGroups[].VpcSecurityGroupId == $sgId and .DBSubnetGroup.DBSubnetGroupName == $sbname and .DBSubnetGroup.Subnets[].SubnetIdentifier==$subnet1 and .DBSubnetGroup.Subnets[].SubnetIdentifier==$subnet2  and .DBSubnetGroup.VpcId==$vpcId and .StorageType==$sttype and .DeletionProtection ==false and .MonitoringInterval==0 and .MaxAllocatedStorage==null and .EnabledCloudwatchLogsExports==null and .BackupRetentionPeriod ==0) | .EngineVersion'`    
            # and .BackupRetentionPeriod ==0
empty_check_no_echo "$version"  "RDSが正しく作成されていません。\nパラメータをご確認ください"

list=(${version//./ })

if [ ${list[0]} -lt $EngineVersion ]; then
  empty_check $aaaa "RDS"  "RDSのMySQLのバージョンが正しく設定されていません。\nパラメータをご確認ください"
  exit 1
fi
empty_check "$version" "RDS" "RDSが正しく作成されていません。\nパラメータをご確認ください"

echo "ALL Success!!"


