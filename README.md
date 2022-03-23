# assignment2
## Description:

### Network template deploys the below:
1. VPC
2. Subnet: 2 public subnets and 2 private subnets spread across two Availabilty Zones.
3. InternetGateway: An Internet Gateway, with a default route on the public subnets. 
4. VPCGatewayAttachment: attachs the internet gateway to the VPC
5. NATGateway: 2 NAT Gateways in each of the public subnets(one in each AZ), and default routes for them in the private subnets.
6. EIP: 2 EIPs and attach each of them to a NatGateway.
7. RouteTable, Route, and SubnetRouteTableAssociation: specifies a route table for a specified VPC. routes are added to route tables and then the route tables are associated with subnets.

### Servers template deploys the below:
1. SecurityGroup: One security group for created web server EC2 instances and another for the load balancer. Web servers security group opens ports 80 and 22 (inbound) and all ports (outbound). Load balancer security group opens ports 80 (inbound and outbound).
2. LaunchConfiguration: Configurations of created EC2 instances including AMI image to be used, assigned security group, storage type and size, instance type, and user data.
3. AutoScalingGroup: attachs launch configuration, private subnets group, minimum desirable number of instances and maximum desirable number of instances. In addition to the load balancer TargetGroup.
4. TargetGroup: Group of instances that will be served by the load balancer in addition to the health check rules.
5. LoadBalancer: Assigns security group to the load balancer and configure the load balancer to conenct to the 2 public networks.
6. Listener: Configure the lister to use port 80 and attach it to the load balancer. It also configures the load balancer to forward requests to the target group.
7. ListenerRule: Creates a rule that consists of an action (forward), priority and a condition and assign it to the listener of the load balancer.


### Network template parameters:
1. EnvironmentName: a name prefixed to created resources.
2. VpcCIDR: IP range for the VPC
3. PublicSubnet1CIDR: IP range for the first public subnet
4. PublicSubnet2CIDR: IP range for the second public subnet
5. PrivateSubnet1CIDR: IP range for the first private subnet
6. PrivateSubnet2CIDR: IP range for the second private subnet

### Servers template parameters:
1. EnvironmentName: a name prefixed to created resources.
2. KeyName: The name of the private key pem file
3. AMItoUse: ID of the AMI image

### Network template resources:
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

2. InternetGateway
```
    InternetGateway:
        Type: AWS::EC2::InternetGateway
        Properties:
            Tags:
                - Key: Name
                  Value: !Ref EnvironmentName 
```

3. VPCGatewayAttachment: attachs the internet gateway to the VPC.
```
    InternetGatewayAttachment:
        Type: AWS::EC2::VPCGatewayAttachment
        Properties:
            InternetGatewayId: !Ref InternetGateway
            VpcId: !Ref VPC
```

4. Subnet: creates a subnet, then assigns it to the VPC and the availability zone. MapPublicIpOnLaunch Indicates whether instances launched in this subnet receive a public IPv4 address
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

5. EIP: creates elastic IP address. DependsOn attribute you can specify that the creation of a specific resource follows another. Domain indicates whether the Elastic IP address is for use with instances in a VPC or instance in EC2-Classic.
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

6. NatGateway: creates NAT Gateways and assign them to public subnets and then assign created Elastic IP addresses to them.
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

7. RouteTable, Route and SubnetRouteTableAssociation: specifies a route table for a specified VPC. After you create a route table, you can add routes and associate the table with a subnet.
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