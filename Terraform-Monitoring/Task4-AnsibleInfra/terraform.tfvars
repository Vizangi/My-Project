environments = {
  dev = {
    subnet_prefix = "172.20.0"
    server_count  = 8
  }
  staging = {
    subnet_prefix = "172.20.1"
    server_count  = 8
  }
  prod = {
    subnet_prefix = "172.20.2"
    server_count  = 8
  }
}

ssh_user     = "ansible_user"
ssh_password = "your_very_secure_password"
