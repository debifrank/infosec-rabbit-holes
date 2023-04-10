# Prerequisites

- An Azure subscription. If you do not have an Azure account, create one now. This tutorial can be completed using only the services included in an Azure free account.
- Terraform 0.14.9 or later
- The Azure CLI Tool installed

## Install Terraform

- You will need to have Terraform installed already
- For instructions on installing please see [https://developer.hashicorp.com/terraform/tutorials/azure-get-started/install-cli](https://developer.hashicorp.com/terraform/tutorials/azure-get-started/install-cli)

## Install Azure CLI in Windows

- Open an administrative PowerShell and run:

```powershell
Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; rm .\AzureCLI.msi
```

## Authenticate with Azure CLI

- In your terminal run the following and supply credentials:

```powershell
az login
```

- In the resulting data output, locate the Subscription you wish to use and copy the `id`
- Set the `id` to an environment variable so we can reference it more easily:

```powershell
$Env:SubID = "<id>"
```

- Issue the following command to set the selected Subscription:

```powershell
az account set --subscription $Env:SubID
```

## Create a Service Principal

- Best practices would advise that you create a special service principal for deploying terraform scripts
- To do so, execute the following command:

```powershell
az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/$Env:SubID"
```

## Setup Environment

- Take the response information from creating your Service Principal and create the following environment variables:

```powershell
$Env:ARM_CLIENT_ID = "<APPID_VALUE>"
$Env:ARM_CLIENT_SECRET = "<PASSWORD_VALUE>"
$Env:ARM_SUBSCRIPTION_ID = $Env:SubID
$Env:ARM_TENANT_ID = "<TENANT_VALUE>"
```

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