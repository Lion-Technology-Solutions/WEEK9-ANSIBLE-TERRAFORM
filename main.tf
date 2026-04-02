provider "aws" {
  region = "ca-central-1"
}

# ---------------------------
# Get latest Amazon Linux AMI dynamically
# ---------------------------
data "aws_ami" "latest_amazon_linux" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# ---------------------------
# Security Group (SSH access)
# ---------------------------
resource "aws_security_group" "ansible_sg" {
  name        = "ansible-sg"
  description = "Allow SSH"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # tighten in production
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------------------------
# EC2 Instances (count = 3)
# ---------------------------
resource "aws_instance" "ansible_nodes" {
  count         = 3
  ami           = data.aws_ami.latest_amazon_linux.id
  instance_type = "t2.micro"
  key_name      = "sept23"

  vpc_security_group_ids = [aws_security_group.ansible_sg.id]

  tags = {
    Name = "ansible-node-${count.index + 1}"
  }
}

# ---------------------------
# Generate Ansible Inventory
# ---------------------------
resource "local_file" "ansible_inventory" {
  filename = "${path.module}/inventory.ini"

  content = <<EOT
[web]
%{ for instance in aws_instance.ansible_nodes ~}
${instance.public_ip} ansible_user=ec2-user
%{ endfor ~}

[web:vars]
ansible_ssh_private_key_file=~/.ssh/sept23.pem
EOT
}

# ---------------------------
# Output IPs
# ---------------------------
output "instance_ips" {
  value = [for i in aws_instance.ansible_nodes : i.public_ip]
}