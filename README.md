# Terraform for Pivotal Ops Manager on GCP

This is a distillation of the [instructions](https://docs.pivotal.io/runtimes/pks/1-0/) for installing Pivotal Container Service on Google Compute Platform (GCP), specifically the section regarding installing [BOSH and Operations Manager](https://docs.pivotal.io/runtimes/pks/1-0/gcp-prepare-env.html) into an easy to deploy Terraform.

## Prerequisites

* [Terraform](https://www.terraform.io/downloads.html)
* [gcloud cli](https://cloud.google.com/sdk/downloads)

## Getting Started

Clone the repo:

```
$ git clone https://github.com/paulczar/terraform-opsman-gcp.git
$ cd terraform-opsman-gcp
```


Create a GCP service account for Terraform to use:

```
$ gcloud iam service-accounts create terraform \
  --display-name "Terraform admin account"

$ gcloud iam service-accounts keys create ~/.config/gcloud/terraform-admin.json \
  --iam-account terraform@<gcloud project>.iam.gserviceaccount.com

$ gcloud projects add-iam-policy-binding pgtm-pczarkowski \
    --member serviceAccount:terraform@<gcloud project>.iam.gserviceaccount.com --role roles/editor
```

Initialize Terraform:

```
$ terraform init

Initializing provider plugins...

The following providers do not have any version constraints in configuration,
so the latest version was installed.

To prevent automatic upgrades to new major versions that may contain breaking
changes, it is recommended to add version = "..." constraints to the
corresponding provider blocks in configuration, with the constraint strings
suggested below.

* provider.google: version = "~> 1.5"
* provider.local: version = "~> 1.1"

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.

```

Log onto Pivotal Network and get the URL for the Ops Manager image. See [here](https://docs.pivotal.io/runtimes/pks/1-0/gcp-om-deploy.html#select-tgz).

Set the content of the environment variable `TF_VAR_opsman_image` to that URL:

```
$ export TF_VAR_opsman_image=https://storage.googleapis.com/.../....tar.gz
```

Set your the environment variable `TF_VAR_project` to match your google project ID:

```
$ gcloud info | grep Project
Project: [XXXXXX]
$ export TF_VAR_project=XXXXXX
```

There are a small amount of other customizations you can make via `variables.tf`, but this should work out of the box.

Run Terraform:

```
$ terraform apply
...
...
Terraform will perform the following actions:
...
...
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes
...
...
Outputs:

Opsman URL = https://ip.of.opsman.server
google config =
Project ID: xxxxxxx
Default deployment tag: mydemo
Auth Json: ./google.json
...
...
```

Once completed Terraform will provide you a output which consists of the Opsman URL and the settings you should configure Operations Manager with once its availalble.

Copy and paste the URL provided by the output into your Browser and continue to configure it based on the Terraform output.
