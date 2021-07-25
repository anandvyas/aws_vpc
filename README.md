## AWS VPC Module
This module is for 
- VPC
- Subnets (Public/Private) [Different AZ]
  - Covering three AZ in one region
    - 3 private subnet for Private (RDS, EKS, VM's)
    - 3 public subnets for ALB and specific requirement 
- Network ACL
- Route table
- Route table association
- Internet Gateway
- NAT Gateway
- Elastic IP 

![](https://csharpcorner.azureedge.net/article/getting-started-with-vpc-virtual-private-cloud-part3/Images/1.png)

### Required Variables
- Project:  Name of the project (WSP/ESSA/AMENA)
- Env: Name of the environment (Prod/Stag/dev)
- VPC_CIDR_BLOCK: Range of the VPC CIDR (Default: 0.0.0.0/16)
- Private subnets
  ```
  variable "publicSubnets" {
    type = map
    default = {
            us-east-1a = "0.0.0.0/0"
            us-east-1b = "0.0.0.0/0"
            us-east-1c = "0.0.0.0/0"
        }
    }

- Private subnets
``` 
  variable "privateSubnets" {
    type = map
    default = {
            us-east-1a = "0.0.0.0/0"
            us-east-1b = "0.0.0.0/0"
            us-east-1c = "0.0.0.0/0"
        }
    }
```
