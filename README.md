# Terraform Workspaces — Multi-Environment EC2 Deployment

A hands-on project that uses **Terraform Workspaces** to deploy differently-sized
EC2 instances for **dev**, **stage**, and **prod** environments — all from the
exact same configuration code.

---

## Table of Contents

- [Part 1 — Understanding Terraform Workspaces](#part-1--understanding-terraform-workspaces)
  - [What is a Terraform Workspace?](#what-is-a-terraform-workspace)
  - [Why Do Workspaces Exist?](#why-do-workspaces-exist)
  - [How State Files Work Per Workspace](#how-state-files-work-per-workspace)
  - [Workspaces vs Separate Directories/Backends](#workspaces-vs-separate-directoriesbackends)
  - [Core Workspace Commands](#core-workspace-commands)
  - [The `terraform.workspace` Built-in Value](#the-terraformworkspace-built-in-value)
- [Part 2 — This Project](#part-2--this-project)
  - [Project Structure](#project-structure)
  - [Architecture Overview](#architecture-overview)
  - [How This Project Uses Workspaces](#how-this-project-uses-workspaces)
  - [Prerequisites](#prerequisites)
  - [Setup & Usage](#setup--usage)
  - [Expected Output](#expected-output)
  - [Cleanup](#cleanup)
  - [Troubleshooting](#troubleshooting)
  - [Security Notes](#security-notes)

---

# Part 1 — Understanding Terraform Workspaces

## What is a Terraform Workspace?

A **Terraform workspace** is an isolated instance of state for a single
Terraform configuration. In plain terms: it lets you reuse the **same**
`.tf` code to manage **multiple, completely separate sets of infrastructure**
— for example, a dev environment and a production environment — without
copying your code into multiple folders.

Every Terraform project always has **at least one workspace**, called
`default`, even if you never explicitly create one.

```bash
terraform workspace show
# Output: default
```

## Why Do Workspaces Exist?

Imagine you have a project that creates an EC2 instance. Without workspaces,
if you wanted a "dev" version and a "prod" version of that instance, you
would need to either:

- **Copy-paste** your entire `.tf` codebase into two separate folders (`dev/` and `prod/`) — leading to duplicated code that drifts out of sync over time, or
- **Manually rename** your state file every time you switch between environments — risky and easy to get wrong

Workspaces solve this by letting Terraform automatically track a **separate
state file per workspace**, while you keep using the **exact same `.tf` files**.

## How State Files Work Per Workspace

Each workspace gets its own state file, so Terraform never confuses
resources between environments. The exact storage location depends on
your backend:

### Local Backend (default, no remote backend configured)

```
terraform.tfstate.d/
├── dev/
│   └── terraform.tfstate
├── stage/
│   └── terraform.tfstate
└── prod/
    └── terraform.tfstate
```

### S3 Remote Backend

If your backend looks like this:

```hcl
terraform {
  backend "s3" {
    bucket = "my-terraform-state-bucket"
    key    = "project/terraform.tfstate"
    region = "us-east-1"
  }
}
```

Terraform automatically namespaces each workspace's state under an `env:/`
prefix in the SAME bucket:

```
s3://my-terraform-state-bucket/project/terraform.tfstate                  ← default workspace
s3://my-terraform-state-bucket/env:/dev/project/terraform.tfstate          ← dev workspace
s3://my-terraform-state-bucket/env:/stage/project/terraform.tfstate        ← stage workspace
s3://my-terraform-state-bucket/env:/prod/project/terraform.tfstate         ← prod workspace
```

> **No backend configuration changes are needed** to support workspaces —
> this namespacing happens automatically the moment you run
> `terraform workspace new <name>`.

## Workspaces vs Separate Directories/Backends

Workspaces are convenient, but they are **not always the safest choice**
for environment separation. Here's an honest comparison:

| | Terraform Workspaces | Separate Directories / Backend Configs |
|---|---|---|
| **Code duplication** | None — one set of `.tf` files | Some — typically one folder per environment |
| **Environment visibility** | Hidden — you must run `terraform workspace show` to know which env is active | Explicit — the folder/backend key name tells you |
| **Risk of mistakes** | ⚠️ Higher — easy to `apply`/`destroy` in the wrong workspace without noticing | Lower — you physically `cd` into the right folder |
| **IAM permission separation** | Harder — same backend/bucket for all environments | Easier — can use separate buckets/accounts per environment |
| **Best for** | Quick environment variants of the SAME infrastructure (e.g. this lab) | Production-grade setups where strict isolation between dev/stage/prod matters |

> ⚠️ **Industry note:** Many teams (including general HashiCorp guidance)
> recommend workspaces for things like feature-branch testing or
> short-lived environment variants, but prefer fully separate state files
> (via distinct backend keys) for permanent dev/stage/prod separation —
> specifically because it is too easy to forget which workspace is active
> and accidentally apply changes to the wrong environment.

## Core Workspace Commands

```bash
# Show which workspace is currently active
terraform workspace show

# List all workspaces that exist
terraform workspace list

# Create a new workspace
terraform workspace new dev

# Switch to an existing workspace
terraform workspace select prod

# Delete a workspace (must not be the currently active one, and must have no resources)
terraform workspace delete stage
```

## The `terraform.workspace` Built-in Value

Terraform exposes the name of the currently active workspace as a
**built-in read-only value**: `terraform.workspace`. You can use it
directly inside your `.tf` files to make decisions based on which
environment is active — which is exactly what this project does.

```hcl
# Example: tag a resource with its environment name automatically
tags = {
  Environment = terraform.workspace   # becomes "dev", "stage", or "prod"
}
```

---

# Part 2 — This Project

## Project Structure

```
terraform-workspaces-project/
├── main.tf                          # Root configuration — calls the module
├── terraform.tfvars                 # Supplies the "ami" variable value
├── .gitignore                       # Excludes state files and secrets from Git
├── modules/
│   └── ec2_instance/
│       ├── main.tf                  # Defines the actual aws_instance resource
│       ├── variables.tf             # Declares the module's input variables
│       └── outputs.tf               # Exposes instance details back to the root
└── README.md                        # This file
```

## Architecture Overview

```
┌───────────────────────────────────────────────────────────────────┐
│                                                                     │
│   terraform.tfvars  ──► provides: ami                              │
│                                                                     │
│   main.tf (ROOT)                                                    │
│     ├── variable "ami"            (string, no default)             │
│     ├── variable "instance_type"  (map: dev/stage/prod sizes)       │
│     │                                                               │
│     └── module "ec2_instance" ──────────────────────────────┐      │
│              │                                               │      │
│              │   ami            = var.ami                   │      │
│              │   instance_type  = lookup(map, workspace, …)  │      │
│              │   instance_name  = "myapp-server"             │      │
│              ▼                                               │      │
│   modules/ec2_instance/main.tf                                │      │
│     └── resource "aws_instance" "this"                        │      │
│              tags.Environment = terraform.workspace ◄─────────┘      │
│                                                                     │
│   Active workspace decides which instance_type gets used:          │
│     "dev"   → t2.micro                                              │
│     "stage" → t2.medium                                             │
│     "prod"  → t2.xlarge                                             │
│                                                                     │
└───────────────────────────────────────────────────────────────────┘
```

## How This Project Uses Workspaces

This project provisions **one EC2 instance**, but the **size of that
instance automatically changes** depending on which Terraform workspace
is active, thanks to this line in the root `main.tf`:

```hcl
instance_type = lookup(var.instance_type, terraform.workspace, "t2.micro")
```

| Active Workspace | `terraform.workspace` value | Instance Type Selected |
|---|---|---|
| `dev` | `"dev"` | `t2.micro` |
| `stage` | `"stage"` | `t2.medium` |
| `prod` | `"prod"` | `t2.xlarge` |
| `default` (or any unmapped name) | anything not in the map | `t2.micro` (safety fallback) |

The instance's `Name` and `Environment` tags also automatically reflect the
active workspace — so even inside the AWS Console, it's instantly clear
which environment an instance belongs to.

## Prerequisites

| Requirement | Purpose |
|---|---|
| **Terraform** installed | [Install Guide](https://developer.hashicorp.com/terraform/install) |
| **AWS account** with credentials configured | Run `aws configure` |
| A valid **AMI ID** for your region | Already provided in `terraform.tfvars` for `us-east-1` |

## Setup & Usage

### Step 1 — Initialize Terraform

```bash
terraform init
```

This downloads the AWS provider and sets up the module reference.

### Step 2 — Create and Switch to the "dev" Workspace

```bash
terraform workspace new dev
```

> If the workspace already exists, use `terraform workspace select dev` instead.

### Step 3 — Preview the Plan

```bash
terraform plan
```

You should see a `t2.micro` instance about to be created (since we're in `dev`).

### Step 4 — Apply

```bash
terraform apply
```

Type `yes` to confirm.

### Step 5 — Switch to "stage" and Repeat

```bash
terraform workspace new stage
terraform plan      # Notice instance_type is now t2.medium
terraform apply
```

### Step 6 — Switch to "prod" and Repeat

```bash
terraform workspace new prod
terraform plan      # Notice instance_type is now t2.xlarge
terraform apply
```

### Step 7 — Confirm All Three Exist Independently

```bash
terraform workspace list
```

```
  default
  dev
  stage
* prod
```

The `*` shows which workspace is currently active. Each workspace has its
own state file and its own EC2 instance — switching workspaces does NOT
destroy or affect the others.

## Expected Output

After running `terraform apply` in the `dev` workspace:

```
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

current_workspace   = "dev"
instance_id         = "i-0abc123def456"
instance_type_used  = "t2.micro"
public_ip           = "54.12.34.56"
```

Switching to `prod` and applying again:

```
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

current_workspace   = "prod"
instance_id         = "i-0xyz987abc654"
instance_type_used  = "t2.xlarge"
public_ip           = "54.98.76.54"
```

Notice: **two completely separate EC2 instances now exist** — one per
workspace — and neither apply affected the other's state.


## Cleanup

Destroy resources **per workspace** — switching workspaces first:

```bash
terraform workspace select dev
terraform destroy

terraform workspace select stage
terraform destroy

terraform workspace select prod
terraform destroy
```

Then, optionally, delete the workspaces themselves (you must switch to
`default` first, since you cannot delete the currently active workspace):

```bash
terraform workspace select default
terraform workspace delete dev
terraform workspace delete stage
terraform workspace delete prod
```

## Troubleshooting

| Problem | Cause | Fix |
|---|---|---|
| `Error: Workspace "dev" does not exist` | Tried to `select` a workspace that was never created | Use `terraform workspace new dev` instead of `select` the first time |
| `Error: Invalid AMI ID` | AMI in `terraform.tfvars` doesn't exist in your region | Update `ami` in `terraform.tfvars` with a valid AMI for your region |
| Instance type doesn't change between environments | Workspace name doesn't match a key in the `instance_type` map | Workspace names must be exactly `dev`, `stage`, or `prod` (case-sensitive) |
| `terraform destroy` removes the wrong environment's resources | Active workspace wasn't checked before running destroy | Always run `terraform workspace show` before `apply`/`destroy` |
| Module not found error during `init` | Module folder/files missing or path incorrect | Confirm `modules/ec2_instance/main.tf` exists relative to the root `main.tf` |

## Security Notes

- **Always check the active workspace** (`terraform workspace show`) before
  running `terraform apply` or `terraform destroy` — workspaces do not
  visually warn you which environment you're about to affect
- For real production use, consider a **remote backend with state locking**
  (e.g. S3 + DynamoDB) rather than local state, especially once multiple
  people or workspaces are involved
- Never hardcode AWS credentials inside `.tf` or `.tfvars` files — use
  `aws configure` or environment variables instead
- Consider restricting `prod` workspace access via separate IAM roles or
  a separate AWS account if your organization requires strict environment
  isolation

---

## Author

**ONEIL KIMBI**
Version: v1.0.0
