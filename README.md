# assignment2

## Network Template:
### Network template deploys the below:
1. VPC
2. Subnet: 2 public subnets and 2 private subnets spread across two Availabilty Zones.
3. InternetGateway: An Internet Gateway, with a default route on the public subnets. 
4. VPCGatewayAttachment: attachs the internet gateway to the VPC
5. NATGateway: 2 NAT Gateways in each of the public subnets(one in each AZ), and default routes for them in the private subnets.
6. EIP: 2 EIPs and attach each of them to a NatGateway.
7. RouteTable, Route, and SubnetRouteTableAssociation: specifies a route table for a specified VPC. routes are added to route tables and then the route tables are associated with subnets.

![ScreenShot](https://william-fisher-github-screenshots.s3.amazonaws.com/assignment1_screenshots/assignment2/001.JPG)

### Parameters:
1. EnvironmentName: A name prefixed to created resources.
2. VpcCIDR: IP range for the VPC
3. PublicSubnet1CIDR: IP range for the first public subnet
4. PublicSubnet2CIDR: IP range for the second public subnet
5. PrivateSubnet1CIDR: IP range for the first private subnet
6. PrivateSubnet2CIDR: IP range for the second private subnet

### Resources:
1. VPC: 
```
    VPC: 
        Type: AWS::EC2::VPC
        Properties:
            CidrBlock: !Ref VpcCIDR
            EnableDnsHostnames: true
            Tags: 
                - Key: Name 
                  Value: !Ref EnvironmentName
```
![ScreenShot](https://william-fisher-github-screenshots.s3.amazonaws.com/assignment1_screenshots/assignment2/002.jpg)

2. InternetGateway and VPCGatewayAttachment: creates an internet gateway and attachs it to the VPC.
```
    InternetGateway:
        Type: AWS::EC2::InternetGateway
        Properties:
            Tags:
                - Key: Name
                  Value: !Ref EnvironmentName 
    InternetGatewayAttachment:
        Type: AWS::EC2::VPCGatewayAttachment
        Properties:
            InternetGatewayId: !Ref InternetGateway
            VpcId: !Ref VPC
```
![ScreenShot](https://william-fisher-github-screenshots.s3.amazonaws.com/assignment1_screenshots/assignment2/003.jpg)

3. Subnet: creates a subnet, then assigns it to the VPC and the availability zone. 
    * MapPublicIpOnLaunch: Indicates whether instances launched in this subnet receive a public IPv4 address
```
    PublicSubnet1: 
        Type: AWS::EC2::Subnet
        Properties:
            VpcId: !Ref VPC
            AvailabilityZone: !Select [ 0, !GetAZs '' ]
            CidrBlock: !Ref PublicSubnet1CIDR
            MapPublicIpOnLaunch: true
            Tags: 
                - Key: Name 
                  Value: !Sub ${EnvironmentName} Public Subnet (AZ1)
    PublicSubnet2: 
        Type: AWS::EC2::Subnet
        Properties:
            VpcId: !Ref VPC
            AvailabilityZone: !Select [ 1, !GetAZs '' ]
            CidrBlock: !Ref PublicSubnet2CIDR
            MapPublicIpOnLaunch: true
            Tags: 
                - Key: Name 
                  Value: !Sub ${EnvironmentName} Public Subnet (AZ2)
    PrivateSubnet1: 
        Type: AWS::EC2::Subnet
        Properties:
            VpcId: !Ref VPC
            AvailabilityZone: !Select [ 0, !GetAZs '' ]
            CidrBlock: !Ref PrivateSubnet1CIDR
            MapPublicIpOnLaunch: false
            Tags: 
                - Key: Name 
                  Value: !Sub ${EnvironmentName} Private Subnet (AZ1)
    PrivateSubnet2: 
        Type: AWS::EC2::Subnet
        Properties:
            VpcId: !Ref VPC
            AvailabilityZone: !Select [ 1, !GetAZs '' ]
            CidrBlock: !Ref PrivateSubnet2CIDR
            MapPublicIpOnLaunch: false
            Tags: 
                - Key: Name 
                  Value: !Sub ${EnvironmentName} Private Subnet (AZ2)
```
![ScreenShot](https://william-fisher-github-screenshots.s3.amazonaws.com/assignment1_screenshots/assignment2/004.jpg)

4. EIP: creates elastic IP address for each subnet. 
    * DependsOn: attribute you can specify that the creation of a specific resource follows another. 
    * Domain: indicates whether the Elastic IP address is for use with instances in a VPC or instance in EC2-Classic.
```
    NatGateway1EIP:
        Type: AWS::EC2::EIP
        DependsOn: InternetGatewayAttachment
        Properties: 
            Domain: vpc
    NatGateway2EIP:
        Type: AWS::EC2::EIP
        DependsOn: InternetGatewayAttachment
        Properties:
            Domain: vpc
```
![ScreenShot](https://william-fisher-github-screenshots.s3.amazonaws.com/assignment1_screenshots/assignment2/005.jpg)

5. NatGateway: creates NAT Gateways and assigns them to public subnets and then assigns created Elastic IP addresses to them.
```
    NatGateway1: 
        Type: AWS::EC2::NatGateway
        Properties: 
            AllocationId: !GetAtt NatGateway1EIP.AllocationId
            SubnetId: !Ref PublicSubnet1
    NatGateway2: 
        Type: AWS::EC2::NatGateway
        Properties:
            AllocationId: !GetAtt NatGateway2EIP.AllocationId
            SubnetId: !Ref PublicSubnet2
```
![ScreenShot](https://william-fisher-github-screenshots.s3.amazonaws.com/assignment1_screenshots/assignment2/006.jpg)

6. RouteTable, Route and SubnetRouteTableAssociation: specifies a route table for a specified VPC. After you create a route table, you can add routes and associate the table with a subnet.
```
    PublicRouteTable:
        Type: AWS::EC2::RouteTable
        Properties: 
            VpcId: !Ref VPC
            Tags: 
                - Key: Name 
                  Value: !Sub ${EnvironmentName} Public Routes
    DefaultPublicRoute: 
        Type: AWS::EC2::Route
        DependsOn: InternetGatewayAttachment
        Properties: 
            RouteTableId: !Ref PublicRouteTable
            DestinationCidrBlock: 0.0.0.0/0
            GatewayId: !Ref InternetGateway
    PublicSubnet1RouteTableAssociation:
        Type: AWS::EC2::SubnetRouteTableAssociation
        Properties:
            RouteTableId: !Ref PublicRouteTable
            SubnetId: !Ref PublicSubnet1
    PublicSubnet2RouteTableAssociation:
        Type: AWS::EC2::SubnetRouteTableAssociation
        Properties:
            RouteTableId: !Ref PublicRouteTable
            SubnetId: !Ref PublicSubnet2
    PrivateRouteTable1:
        Type: AWS::EC2::RouteTable
        Properties: 
            VpcId: !Ref VPC
            Tags: 
                - Key: Name 
                  Value: !Sub ${EnvironmentName} Private Routes (AZ1)
    DefaultPrivateRoute1:
        Type: AWS::EC2::Route
        Properties:
            RouteTableId: !Ref PrivateRouteTable1
            DestinationCidrBlock: 0.0.0.0/0
            NatGatewayId: !Ref NatGateway1
    PrivateSubnet1RouteTableAssociation:
        Type: AWS::EC2::SubnetRouteTableAssociation
        Properties:
            RouteTableId: !Ref PrivateRouteTable1
            SubnetId: !Ref PrivateSubnet1
    PrivateRouteTable2:
        Type: AWS::EC2::RouteTable
        Properties: 
            VpcId: !Ref VPC
            Tags: 
                - Key: Name 
                  Value: !Sub ${EnvironmentName} Private Routes (AZ2)
    DefaultPrivateRoute2:
        Type: AWS::EC2::Route
        Properties:
            RouteTableId: !Ref PrivateRouteTable2
            DestinationCidrBlock: 0.0.0.0/0
            NatGatewayId: !Ref NatGateway2
    PrivateSubnet2RouteTableAssociation:
        Type: AWS::EC2::SubnetRouteTableAssociation
        Properties:
            RouteTableId: !Ref PrivateRouteTable2
            SubnetId: !Ref PrivateSubnet2
```

### The network template outputs references to the below resources. Each output has a name and a value:
```
    VPC: 
        Description: A reference to the created VPC
        Value: !Ref VPC
        Export:
          Name: !Sub ${EnvironmentName}-VPCID
    VPCPublicRouteTable:
        Description: Public Routing
        Value: !Ref PublicRouteTable
        Export:
          Name: !Sub ${EnvironmentName}-PUB-RT
    VPCPrivateRouteTable1:
        Description: Private Routing AZ1
        Value: !Ref PrivateRouteTable1
        Export:
          Name: !Sub ${EnvironmentName}-PRI1-RT
    VPCPrivateRouteTable2:
        Description: Private Routing AZ2
        Value: !Ref PrivateRouteTable2
        Export:
          Name: !Sub ${EnvironmentName}-PRI2-RT
    PublicSubnets:
        Description: A list of the public subnets
        Value: !Join [ ",", [ !Ref PublicSubnet1, !Ref PublicSubnet2 ]]
        Export:
          Name: !Sub ${EnvironmentName}-PUB-NETS
    PrivateSubnets:
        Description: A list of the private subnets
        Value: !Join [ ",", [ !Ref PrivateSubnet1, !Ref PrivateSubnet2 ]]
        Export:
          Name: !Sub ${EnvironmentName}-PRIV-NETS
    PublicSubnet1:
        Description: A reference to the public subnet in the 1st Availability Zone
        Value: !Ref PublicSubnet1
        Export:
          Name: !Sub ${EnvironmentName}-PUB1-SN
    PublicSubnet2: 
        Description: A reference to the public subnet in the 2nd Availability Zone
        Value: !Ref PublicSubnet2
        Export:
          Name: !Sub ${EnvironmentName}-PUB2-SN
    PrivateSubnet1:
        Description: A reference to the private subnet in the 1st Availability Zone
        Value: !Ref PrivateSubnet1
        Export:
          Name: !Sub ${EnvironmentName}-PRI1-SN
    PrivateSubnet2: 
        Description: A reference to the private subnet in the 2nd Availability Zone
        Value: !Ref PrivateSubnet2
        Export:
          Name: !Sub ${EnvironmentName}-PRI2-SN
          
```

## Web Servers Template:
### Web servers template deploys the below:
1. SecurityGroup: One security group for created web server EC2 instances and another for the load balancer. Web servers security group opens ports 80 and 22 (inbound) and all ports (outbound). Load balancer security group opens ports 80 (inbound and outbound).
2. LaunchConfiguration: Configurations of created EC2 instances including AMI image to be used, assigned security group, storage type and size, instance type, and user data.
3. AutoScalingGroup: attachs launch configuration, private subnets group, minimum desirable number of instances and maximum desirable number of instances. In addition to the load balancer TargetGroup.
4. TargetGroup: Group of instances that will be served by the load balancer in addition to the health check rules.
5. LoadBalancer: Assigns security group to the load balancer and configure the load balancer to conenct to the 2 public networks.
6. Listener: Configure the lister to use port 80 and attach it to the load balancer. It also configures the load balancer to forward requests to the target group.
7. ListenerRule: Creates a rule that consists of an action (forward), priority and a condition and assign it to the listener of the load balancer.


### Parameters:
1. EnvironmentName: A name prefixed to created resources.
2. KeyName: The name of the private key pem file
3. AMItoUse: ID of the AMI image

### Resources:
1. SecurityGroup: 
```
  WebServerSecGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Allow http to our hosts and SSH from local only
      VpcId:
        Fn::ImportValue:
          !Sub "${EnvironmentName}-VPCID"
      SecurityGroupIngress:
      - IpProtocol: tcp
        FromPort: 80
        ToPort: 80
        CidrIp: 0.0.0.0/0
      - IpProtocol: tcp
        FromPort: 22
        ToPort: 22
        CidrIp: 0.0.0.0/0
      SecurityGroupEgress:
      - IpProtocol: tcp
        FromPort: 0
        ToPort: 65535
        CidrIp: 0.0.0.0/0
  LBSecGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Allow http to our load balancer
      VpcId:
        Fn::ImportValue:
          !Sub "${EnvironmentName}-VPCID"
      SecurityGroupIngress:
      - IpProtocol: tcp
        FromPort: 80
        ToPort: 80
        CidrIp: 0.0.0.0/0
      SecurityGroupEgress:
      - IpProtocol: tcp
        FromPort: 80
        ToPort: 80
        CidrIp: 0.0.0.0/0
```

2. LoadBalancer, Listener, and ListenerRule:
```
  WebAppLB:
    Type: AWS::ElasticLoadBalancingV2::LoadBalancer
    Properties:
      Subnets:
      - Fn::ImportValue: !Sub "${EnvironmentName}-PUB1-SN"
      - Fn::ImportValue: !Sub "${EnvironmentName}-PUB2-SN"
      SecurityGroups:
      - Ref: LBSecGroup
  Listener:
    Type: AWS::ElasticLoadBalancingV2::Listener
    Properties:
      DefaultActions:
      - Type: forward
        TargetGroupArn:
          Ref: WebAppTargetGroup
      LoadBalancerArn:
        Ref: WebAppLB
      Port: 80
      Protocol: HTTP
  ALBListenerRule:
      Type: AWS::ElasticLoadBalancingV2::ListenerRule
      Properties:
        Actions:
        - Type: forward
          TargetGroupArn: !Ref 'WebAppTargetGroup'
        Conditions:
        - Field: path-pattern
          Values: [/]
        ListenerArn: !Ref 'Listener'
        Priority: 1
```

3. TargetGroup:
```
  WebAppTargetGroup:
    Type: AWS::ElasticLoadBalancingV2::TargetGroup
    Properties:
      HealthCheckIntervalSeconds: 10
      HealthCheckPath: /
      HealthCheckProtocol: HTTP
      HealthCheckTimeoutSeconds: 8
      HealthyThresholdCount: 2
      Port: 80
      Protocol: HTTP
      UnhealthyThresholdCount: 5
      VpcId: 
        Fn::ImportValue:
          Fn::Sub: "${EnvironmentName}-VPCID"
```

4. LaunchConfiguration:
```
  WebAppLaunchConfig:
    Type: AWS::AutoScaling::LaunchConfiguration
    Properties:
      UserData:
        Fn::Base64: !Sub |
          #!/bin/bash
          yum update -y
          yum install -y httpd
          systemctl start httpd          
      ImageId: !Ref AMItoUse
      # ToDo: Change the key-pair name, as applicable to you. 
      KeyName: !Ref KeyName
      SecurityGroups:
      - Ref: WebServerSecGroup
      InstanceType: t3.micro
      BlockDeviceMappings:
      - DeviceName: "/dev/sdk"
        Ebs:
          VolumeSize: '10'
```

5. AutoScalingGroup:
```
  WebAppGroup:
    Type: AWS::AutoScaling::AutoScalingGroup
    Properties:
      VPCZoneIdentifier:
      - Fn::ImportValue: 
          !Sub "${EnvironmentName}-PRIV-NETS"
      LaunchConfigurationName:
        Ref: WebAppLaunchConfig
      MinSize: '3'
      MaxSize: '5'
      TargetGroupARNs:
      - Ref: WebAppTargetGroup
```

## Database Servers Template:
### Option 1 (using RDS): 
### This template deploys a multi availability zone MySQL community edition database server. One of the databases will act as a primary server and the other will be a secondary server.
1. DBInstance
2. DBSubnetGroup
3. SecurityGroup

### Option 1 Parameters:
1. EnvironmentName: a name prefixed to created resources.
2. DBPass: admin user password "admin123"

### Option 1 Resources:
1. DBInstance: 
    * AllocatedStorage: sets storage size to the database server.
    * BackupRetentionPeriod: The number of days for which automated backups are retained. Setting this parameter to a positive number enables backups. Setting this parameter to 0 disables automated backups.
    * CopyTagsToSnapshot: A value that indicates whether to copy tags from the DB instance to snapshots of the DB instance. By default, tags are not copied.
    * DBInstanceClass: type of instance
    * DBInstanceIdentifier: A name for the DB instance. If you specify a name, AWS CloudFormation converts it to lowercase.
    * DBName: The name of the database to create when the DB instance is created.
    * DBSubnetGroupName: A DB subnet group to associate with the DB instance. 
    * Engin: DB engine type.
    * EngineVersion: DB engine version.
    * LicenseModel: DB engine licence model.
    * MasterUsername: DB admin user username.
    * MasterUserPassword: DB admin user password.
    * MaxAllocatedStorage: The upper limit in gibibytes (GiB) to which Amazon RDS can automatically scale the storage of the DB instance.
    * MultiAZ: Specifies whether the database instance is a Multi-AZ DB instance deployment. You can't set the AvailabilityZone parameter if the MultiAZ parameter is set to true.
    * PubliclyAccessible: Indicates whether the DB instance is an internet-facing instance. 
    * StorageType: Type of storage assigned to the DB instance.
    * VPCSecurityGroups: A list of the VPC security group IDs to assign to the DB instance.
```
  DB:
    Type: AWS::RDS::DBInstance
    Properties:
      AllocatedStorage: 20
      BackupRetentionPeriod: 0
      CopyTagsToSnapshot: true # default: false
      DBInstanceClass: db.t2.micro
      DBInstanceIdentifier: instalikedb
      DBName: 'InstaLikeDb'
      DBSubnetGroupName: 'DBSubnetGroup'
      Engine: 'mysql'
      EngineVersion: '8.0.20'
      LicenseModel: 'general-public-license'
      MasterUsername: 'admin'
      MasterUserPassword: !Ref DBPass
      MaxAllocatedStorage: 100
      MultiAZ: true
      PubliclyAccessible: false
      StorageType: gp2
      VPCSecurityGroups:
        - Ref: DBSecurityGroup
```

2. DBSubnetGroup:
```
  DBSubnetGroup:
    Type: AWS::RDS::DBSubnetGroup
    Properties:
      DBSubnetGroupDescription: "DBSubnetGroup for RDS MySql instance"
      DBSubnetGroupName: DBSubnetGroup
      SubnetIds:
        - Fn::ImportValue:
            Fn::Sub: "${EnvironmentName}-PRI1-SN"
        - Fn::ImportValue:
            Fn::Sub: "${EnvironmentName}-PRI2-SN"
```

3. SecurityGroup:
```
  DBSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: 'DB security group'
      GroupName: 'UserManagerDBSg'
      SecurityGroupIngress:
        - SourceSecurityGroupId: !Ref ServerSecurityGroup
          IpProtocol: TCP
          FromPort: 3306
          ToPort: 3306
      SecurityGroupEgress:
        - CidrIp: '0.0.0.0/0'
          IpProtocol: -1 # Allow all
      Tags:
        - Key: 'Name'
          Value: 'UserManagerDBSg'
      VpcId:
        Fn::ImportValue:
          Fn::Sub: "${EnvironmentName}-VPCID"

  ServerSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Allow http to our hosts and SSH from local only
      VpcId:
        Fn::ImportValue:
          !Sub "${EnvironmentName}-VPCID"
      SecurityGroupIngress:
      - IpProtocol: tcp
        FromPort: 80
        ToPort: 80
        CidrIp: 0.0.0.0/0
      - IpProtocol: tcp
        FromPort: 22
        ToPort: 22
        CidrIp: 0.0.0.0/0
      SecurityGroupEgress:
      - IpProtocol: tcp
        FromPort: 0
        ToPort: 65535
        CidrIp: 0.0.0.0/0
```

### Option 2 (using Ubuntu EC2 instances):
### This template will deploy 2 ubuntu instance (one in each private subnet) and then configuring MySQL communciaty edition database server on each of them:
1. Instance: Creates 2 EC2 instances (one in each private network).
2. SecurityGroup: Opens port 3306 for both instances.

### Option 2 Parameters:
1. EnvironmentName: A name prefixed to created resources.
2. DbMasterUsername: Admin user username.
3. DbMasterPassword: Admin user password "admin123".
4. KeyName: The name of the private key pem file.
5. AMItoUse: ID of the AMI image.

### Option 2 Resources:
1. SecurityGroup:
```
  DbSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: MySQL security group
      VpcId:
        Fn::ImportValue:
          !Sub "${EnvironmentName}-VPCID"
      SecurityGroupIngress:
        - CidrIp: 0.0.0.0/0
          IpProtocol: tcp
          FromPort: 3306
          ToPort: 3306
        - CidrIp: 0.0.0.0/0
          IpProtocol: tcp
          FromPort: 22
          ToPort: 22
      Tags: 
        - Key: Name 
          Value: !Sub ${EnvironmentName} DbSecurityGroup
```

2. Instance:
```
  DbInstance1:
    Type: AWS::EC2::Instance
    Properties:
      KeyName: !Ref KeyName
      ImageId: !Ref AMItoUse
      InstanceType: t2.micro
      SecurityGroupIds:
        - !GetAtt DbSecurityGroup.GroupId
      SubnetId:
        Fn::ImportValue:
          !Sub "${EnvironmentName}-PRI1-SN"
      UserData: 
        Fn::Base64: !Sub |
          #!/bin/bash -ex
          sudo su
          yum localinstall -y https://dev.mysql.com/get/mysql80-community-release-el7-1.noarch.rpm
          yum install -y mysql-community-server
          systemctl enable mysqld
          systemctl start mysqld
          mysql -u root "-p$(grep -oP '(?<=root@localhost\: )\S+' /var/log/mysqld.log)" -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${DbMasterPassword}'" --connect-expired-password
          mysql -u root "-p${DbMasterPassword}" -e "CREATE USER '${DbMasterUsername}'@'%' IDENTIFIED BY '${DbMasterPassword}'"
          mysql -u root "-p${DbMasterPassword}" -e "GRANT ALL PRIVILEGES ON *.* TO '${DbMasterUsername}'@'%'"
          mysql -u root "-p${DbMasterPassword}" -e "FLUSH PRIVILEGES"
      Tags: 
        - Key: Name 
          Value: !Sub ${EnvironmentName} DB Instance 1

  DbInstance2:
    Type: AWS::EC2::Instance
    Properties:
      KeyName: !Ref KeyName
      ImageId: !Ref AMItoUse
      InstanceType: t2.micro
      SecurityGroupIds:
        - !GetAtt DbSecurityGroup.GroupId
      SubnetId:
        Fn::ImportValue:
          !Sub "${EnvironmentName}-PRI2-SN"
      UserData: 
        Fn::Base64: !Sub |
          #!/bin/bash -ex
          sudo su
          yum localinstall -y https://dev.mysql.com/get/mysql80-community-release-el7-1.noarch.rpm
          yum install -y mysql-community-server
          systemctl enable mysqld
          systemctl start mysqld
          mysql -u root "-p$(grep -oP '(?<=root@localhost\: )\S+' /var/log/mysqld.log)" -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${DbMasterPassword}'" --connect-expired-password
          mysql -u root "-p${DbMasterPassword}" -e "CREATE USER '${DbMasterUsername}'@'%' IDENTIFIED BY '${DbMasterPassword}'"
          mysql -u root "-p${DbMasterPassword}" -e "GRANT ALL PRIVILEGES ON *.* TO '${DbMasterUsername}'@'%'"
          mysql -u root "-p${DbMasterPassword}" -e "FLUSH PRIVILEGES"
      Tags: 
        - Key: Name 
          Value: !Sub ${EnvironmentName} DB Instance 2
```

## To create the stacks on AWS:
1. Run the below shell script and feed in the stack name, YAML file name and parameters file name for each template:
```
#!/bin/bash
aws cloudformation create-stack \
--stack-name $1 \
--template-body file://$2 \
--parameters file://$3
```

2. Run the below commands using AWS CLI:
```
aws cloudformation create-stack --stack-name stack-network --template-body file://1_network.yml --parameters file://1_network_params.json
aws cloudformation create-stack --stack-name stack-apps --template-body file://2_servers.yml --parameters file://2_servers_params.json
aws cloudformation create-stack --stack-name stack-db --template-body file://3_option_2_ec2_mysql.yml --parameters file://3_option_2_ec2_mysql_params.json
```
