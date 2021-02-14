# Define Vpc
resource "aws_vpc" "dev-vpc" {
    cidr_block = "10.0.0.0/16"
    instance_tenancy = "default" 
    tags = {
        Name = "dev-vpc"
    }
}

# Define public subnet
resource "aws_subnet" "dev-subnet" {
    vpc_id = aws_vpc.dev-vpc.id
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = "true"
    availability_zone = "us-east-1a"
    tags = {
        Name = "dev-subnet"
    }
}

# Define Igw
resource "aws_internet_gateway" "dev-igw" {
    vpc_id = aws_vpc.dev-vpc.id
    tags = {
        Name = "dev-igw"
    }
}

# Create route table
resource "aws_route_table" "dev-rt" {
    vpc_id = aws_vpc.dev-vpc.id
    
    route {
        cidr_block = "0.0.0.0/0" 
        gateway_id = aws_internet_gateway.dev-igw.id
    }
    
    tags = {
        Name = "dev-rt"
    }
}

# Joining custom route table and subnet
resource "aws_route_table_association" "dev-subnet-rt"{
    subnet_id = aws_subnet.dev-subnet.id
    route_table_id = aws_route_table.dev-rt.id
}

# Create Security Group
resource "aws_security_group" "dev-ssh-sg" {
    vpc_id = aws_vpc.dev-vpc.id
    
    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = "dev-ssh-sg"
    }
}

# Create EC2 instance
resource "aws_instance" "dev-Webserver" {
    ami = "ami-096fda3c22c1c990a"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.dev-subnet.id
    vpc_security_group_ids = ["${aws_security_group.dev-ssh-sg.id}"]
	user_data = <<-EOF
		#! /bin/bash
        yum install -y apache2
		systemctl start apache2
		systemctl enable apache2
		echo "<h1>Created whole Infrastructure via Terraform</h1>" | tee /var/www/html/index.html
	EOF
	tags = {
		Name = "dev-Webserver"
		Environemt = "dev-"
		Created_by = "Shivani"
		}
    key_name = "remotekeypair"
}
