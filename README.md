# terraform

Create 3 instances with Terraform:
APP (public IP)
DB (NO public IP)
ElasticSearch (NO public IP)


Create a firewall rules:
ALL:* -> LB:443 (test-firewall)
ALL:* -> APP:22 (test-firewall)
APP:* -> DB:22 (yep-mad-test-firewall100200)
APP:* -> ELASTIC:22 (yep-mad-test-firewall200300)
APP:* -> DB:3306 (yep-mad-test-firewall100200)
APP:* -> ELASTIC:9200-9300 (yep-mad-test-firewall200300)
