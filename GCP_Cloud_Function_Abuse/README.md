# Prerequisites

- A subscription with Goocle Cloud Platform. If you do not have a GCP account, create one now. This tutorial can be completed using only the services included in an GCP free account.
- Terraform 0.14.9 or later
- The GCloud CLI installed

# Setup

For the best possible outcome, follow along with the following tutorial to get GCloud and Terraform installed and configured properly for your GCP Account and Project:

- https://developer.hashicorp.com/terraform/tutorials/gcp-get-started/google-cloud-platform-build

# Deploy

- Open a terminal in the directory where this README exists and initialize terraform:

```powershell
terraform init
```

- Apply the changes in the terraform script:

```powershell
terraform apply
```

- When prompted, enter `yes`
- Once the infrastructure is stood up, the endpoints you need will be output to your terminal window

# Tear Down

- When you are done with the lab execute the following in the same directory to destroy the assets

```powershell
terraform destroy
```

- When prompted, enter `yes` and the infrastructure will be removed
