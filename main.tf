


# ami Amazon Machine Image.
# data : aller chercher quelque chose qui existe

# on charge la version la plus recente de ubunut 22


# type et nom local
data "aws_ami" "ubuntu" {

  most_recent = true
  owners      = ["099720109477"] # edtiteur de canonical ubuntu

  # critere de recherche 
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

}




# block ssh

resource "aws_key_pair" "cloud1" {
  key_name   = "cloud1"
  public_key = file("~/.ssh/cloud1.pub")
}


resource "aws_security_group" "web_security" {
  name        = "cloud1-web-security"
  description = "SSH, HTTP, HTTPS"

  # ingress entrant
  # engress sortant

  # from_port to_port = polage ici on cible que 1
  # 
  # description = pour voir dans la console 


  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  # on autorise tout avec le -1 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_instance" "web_instance" {

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type # EC2 mini vps 
  key_name               = aws_key_pair.cloud1.key_name
  vpc_security_group_ids = [aws_security_group.web_security.id]

  root_block_device {
    volume_size = var.volume_size # taille de la / 
  }

  tags = {
    Name = "cloud2" # nom de l instance
  }
}


