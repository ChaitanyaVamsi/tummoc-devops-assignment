data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical's official account

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
# Bastion host

resource "aws_instance" "bastion" {
  ami = data.aws_ami.ubuntu.id
  instance_type = var.bastion_instance
  subnet_id = aws_subnet.public.id
  key_name = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.bastion.id]
  associate_public_ip_address = true
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8 # GB — just enough for the OS
    delete_on_termination = true
    encrypted             = true
  }
  tags = merge(local.common_tags,
 { Name="${local.common_name}-bastion"})

}

resource "aws_instance" "app" {
  ami = data.aws_ami.ubuntu.id
  instance_type = var.app_instance
  subnet_id = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.app.id]
  associate_public_ip_address = false
  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    delete_on_termination = true
    encrypted = true
  }
  user_data = file("setup.sh")
  tags = merge(local.common_tags,{
    Name = "${local.common_name}-app"
  })
}