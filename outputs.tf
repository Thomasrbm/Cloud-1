
#  dans la stdout pour voir une sortie
# id de l image en output

output "ami_id" {
  value = data.aws_ami.ubuntu.id
}


output "ip" {
  value = aws_instance.web_instance.public_ip
}