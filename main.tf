terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 5.0"
        }
    }
}


provider "aws" {
    region = "ap-northeast-1"
}

resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"

    tags = {
        Name = "main"
    }
} 


resource "aws_internet_gateway" "main" {
    vpc_id = aws_vpc.main.id


    tags = {
        Name = "main"
    }
} 

resource "aws_subnet" "public" {
    vpc_id = aws_vpc.main.vpc_id
    map_public_ip_on_launch = true
    availability_zone = "ap-northeast-1"
    cidr_block = "10.0.1.0/24"


    tags = {
        Name = "main"
    }
}

resource "aws_subnet" "private" {
    vpc_id = aws_vpc.main.vpc_id
    availability_zone = "ap-northeast-1"
    cidr_block = "10.0.2.0/24"

    tags = {
        Name = "main"
    }
}

resource "aws_eip" "nat" {
    vpc = true
}

resource "aws_nat_gateway" "main" {
    allocation_id = aws_eip.nat.id
    subnet_id = aws_subnet.public.id


    tags = {
        Name = "main"
    }
}


#public route table
resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.vpc_id

    route = {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main.id
    }

    tags = {
        Name = "main"
    }
}

resource "aws_route_table_association" "public" {
    subnet_id = aws_subnet.public.id
    route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
    vpc_id = aws_vpc.main.id

    route = {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.main.id
    }

    tags = {
        Name = "main"
    }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}