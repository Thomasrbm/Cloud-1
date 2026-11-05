terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 5.0"
        }
    }
}


provider "aws" {
    region = "eu-north-1"
}



# ami Amazon Machine Image.
# data : aller chercher quelque chose qui existe

# on charge la version la plus recente de ubunut 22


# type et nom local
data "aws_ami" "ubuntu" {

    most_recent = true
    owners = ["099720109477"] # edtiteur de canonical ubuntu

    # critere de recherche 
    filter {
        name = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
    }

}


#  dans la stdout pour voir une sortie
# id de l image en output

output "ami_id" {
    value = data.aws_ami.ubuntu.id
}




# block ssh

resource "aws_key_pair" "cloud1" {
    key_name = "cloud1"
    public_key = file("~/.ssh/cloud1.pub")
}


resource "aws_security_group" "web_security" {
    name = "cloud1-web-security"
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
    ami = data.aws_ami.ubuntu.id

}



output "ip" {

}