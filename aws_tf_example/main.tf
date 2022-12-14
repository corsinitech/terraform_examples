terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "4.46.0"
        }
    }
}

provider "aws" {
    region = "us-east-1"
    access_key = var.aws_access_key 
    secret_key = var.aws_access_secret
}

resource "aws_vpc" "tfwebvpc" {
    cidr_block = "10.0.0.0/16"

    tags = {
        Name = "terraform-example"
    }
}

resource "aws_internet_gateway" "tfwebgw" {
    vpc_id = aws_vpc.tfwebvpc.id

    tags = {
        Name = "terraform-example"
    }
}

resource "aws_route_table" "tfwebroute" {
    vpc_id = aws_vpc.tfwebvpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.tfwebgw.id
    }

    route {
        ipv6_cidr_block = "::/0"
        gateway_id = aws_internet_gateway.tfwebgw.id
    }

    tags = {
        Name = "terraform-example"
    }
}

resource "aws_subnet" "tfwebsubnet" {
    vpc_id = aws_vpc.tfwebvpc.id
    cidr_block = "10.0.1.0/24"

    tags = {
        Name = "terraform-example"
    }
}

resource "aws_route_table_association" "tfwebrwassociation" {
    subnet_id = aws_subnet.tfwebsubnet.id
    route_table_id = aws_route_table.tfwebroute.id 
}

resource "aws_security_group" "tfwebsecgru" {
    name = "tfwebsecgru"
    description = "Allows web and ssh traffic into the instance"
    vpc_id = aws_vpc.tfwebvpc.id

    ingress {
        description = "Allow HTTP"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "Allow HTTPS"
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "Allow SSH"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [var.home_ext_ip]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }

    tags = {
        Name = "terraform-example"
    }
}

resource "aws_network_interface" "tfwebnic" {
    subnet_id = aws_subnet.tfwebsubnet.id
    private_ips = ["10.0.1.15"]
    security_groups = [aws_security_group.tfwebsecgru.id]

    tags = {
        Name = "terraform-example"
    }
}

resource "aws_eip" "tfwebeip" {
    vpc = true
    network_interface = aws_network_interface.tfwebnic.id
    associate_with_private_ip = "10.0.1.15"
    depends_on = [aws_internet_gateway.tfwebgw]

    tags = {
        Name = "terraform-example"
    }
}

resource "aws_instance" "tfwebsrv" {
    ami = "ami-0574da719dca65348"
    instance_type = "t2.micro"
    key_name = "tf_example_keypair"
    network_interface {
        network_interface_id = aws_network_interface.tfwebnic.id
        device_index = 0
    }

    user_data = <<-EOF
            #!/bin/bash
            sudo apt update -y
            sudo apt install -y apache2
            sudo service apache2 start
            sudo bash -c 'echo Hello, world > /var/www/html/index.html'
            EOF

    tags = {
        Name = "terraform-example"
    }
}

