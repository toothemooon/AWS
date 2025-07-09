# Bastion Host
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.bastion_instance_type
  key_name               = var.key_pair_name != "" ? var.key_pair_name : null
  vpc_security_group_ids = [aws_security_group.bastion.id]
  subnet_id              = aws_subnet.public[0].id

  # Basic user data for bastion (minimal setup)
  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y htop tmux
              EOF
  )

  tags = {
    Name = "${var.project_name}-bastion"
    Type = "Bastion"
  }
}

# Web Servers in Private Subnets
resource "aws_instance" "web" {
  count = length(aws_subnet.private)

  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = var.key_pair_name != "" ? var.key_pair_name : null
  vpc_security_group_ids = [aws_security_group.web_servers.id]
  subnet_id              = aws_subnet.private[count.index].id

  # User data script to install and configure httpd
  user_data = base64encode(templatefile("${path.module}/user-data-web.sh", {
    server_name = "WebAP-Server-${count.index + 1}"
    az_name     = aws_subnet.private[count.index].availability_zone
  }))

  tags = {
    Name = "${var.project_name}-web-${count.index + 1}"
    Type = "WebServer"
    AZ   = aws_subnet.private[count.index].availability_zone
  }
}

# Target Group Attachments
resource "aws_lb_target_group_attachment" "web" {
  count = length(aws_instance.web)

  target_group_arn = aws_lb_target_group.web_servers.arn
  target_id        = aws_instance.web[count.index].id
  port             = 80
} 