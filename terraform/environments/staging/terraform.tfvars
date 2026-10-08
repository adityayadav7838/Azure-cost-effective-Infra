location                = "centralindia"
environment             = "staging"
vnet_cidr               = "10.0.0.0/16"
aks_node_vm_size        = "Standard_B2as_v2"
postgres_sku            = "B_Standard_B1ms"
postgres_admin_username = "psqladmin"
postgres_admin_password = "Aditya@9811465875"

dns_label               = "myapp-staging"
allowed_ssh_cidrs       = ["125.18.170.18/32"]
bastion_ssh_public_key  = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDAMRQzTqpgjeoDyIf54+wkcYEZiJRAm+NDie5B4HWVXbtOKhltqMmP4TbEU8SxxZSWVAM0OHybDl3llYm9vc4VRyW+r63/c6/IMTD16AVzYyRDJFe8DjL8h1EBSOvL1PawoYuriIlZG4g5/wU6gEqLAYvz6Dbij4dpbMnuSErEE2dYNEjEgNpnVCsnpVUw6rJsWze6/u4aHajZ7c1RiwWJAvCrj2ZmWRRrwLvgUV1ylsVEUJSjxmy5naqu3eU38iAC/X6Hm0iWYwf1qGBhf5rb0RftPx36DAUbINSUd8jc+Q6Hhn2FzXbRRv+NfvFSw7iBvF3eW9uENnVqRNlCYRNOVOTa/fDx3atq7uDcvD8md8I3H4JgH9uvQxrCq97gq6pfsPGFroV1Ql08sL34GBLUYHqYD/l9SLwe5V9BEJUm4VISPdaJrkDy1HMBBrjiI6nM1jKY6emp+Bx/09brkBQ57AEWVzs7rQUWeeEb2a90P3vvYl4swS59+7OuTKP0/AQkb69DKvI/CAuNXvBr81UeUJxLgUrbVROeSj6ozMNwlnDmR5vzUvboQm0cT5KIc7xSag6sFNahma56idGRcppczInf1LkDg3+7ST5UMxYt71K5RrkdrjS4xLQLv8u07h/TUEQUU78oiz9p9tUqmPq1GYgjdpO4WAehPur9KC0uYw== aditya@nixos"

enable_bastion          = true
bastion_vm_size         = "Standard_B2as_v2"

app_image               = "aditya9811/sample-app:v1"
app_replica_count       = 2

docker_username         = "aditya9811"
docker_password         = "dckr_pat_kwKJrgvgVKIndl8B_bs-73Vum6Y"
