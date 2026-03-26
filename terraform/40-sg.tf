# ALB sg
resource "aws_security_group" "alb" {
  name = "${local.common_name}-alb-sg"
  vpc_id      = aws_vpc.main.id
  description = "Security group for the alb"
  ingress {
    description = "http from internet"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress{
    description = "allow all outbound"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(local.common_tags,{Name = "${local.common_name}-alb-sg"})
}

# Bastion Security Group
resource "aws_security_group" "bastion" {
  name = "${local.common_name}-bastion-sg"
  vpc_id      = aws_vpc.main.id
  description = "Security group for the bastion"
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
   egress{
    description = "allow all outbound"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(local.common_tags,{Name = "${local.common_name}-bastion-sg"})
}

# App EC2 Security Group

resource "aws_security_group" "app" {
  name = "${local.common_name}-devServer-sg"
  vpc_id      = aws_vpc.main.id
  description = "sg for app"
  ingress {
    description = "receive traffic from ALB only"
    from_port = 3000
    to_port = 3000
    protocol = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  ingress {
    description = "ssh from bastion only"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }
  egress{
    description = "allow all outbound"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(local.common_tags,{Name = "${local.common_name}-bastion-sg"})
}

resource "aws_security_group" "jenkins" {
  name= "${local.common_name}-jenkins-sg"
  vpc_id = aws_vpc.main.id
  description = "sg for jenkins server"
  ingress {
    description = "ssh from bastion"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }
  egress{
    description = "allow all outbound"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags,{Name = "${local.common_name}-jenkins-sg"})
}