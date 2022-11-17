data "aws_ami" "server_ami" {
  most_recent = true
  owners      = ["309956199498"]

  filter {
    name   = "name"
    values = ["RHEL-9.0.0_HVM-20221027-x86_64-1-Hourly2-GP2"]
  }
}