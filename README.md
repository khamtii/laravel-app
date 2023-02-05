# mini-project
Used Terraform infrastructure management tool to create 3 EC2 instances and put them behind an Elastic Load Balancer, Then exported the public IP addresses of
the 3 instances to a file called host-inventory, Also set up my domain a (ktaltproject.me) with AWS Route53 within the terraform plan, then added an A record 
for subdomain terraform-test that points to the ELB IP address.
Created an Ansible script that uses the host-inventory file Terraform created to install Apache, set timezone to Africa/Lagos and displays a simple HTML page that 
displays content to clearly identify on all 3 EC2 instances.
