# =============================================================================
# main.tf  (ROOT MODULE)
# -----------------------------------------------------------------------------
# This is the ENTRY POINT of the project — the file Terraform reads first
# when you run "terraform init/plan/apply" from this folder.
#
# Its job is simple:
#   1. Tell Terraform which cloud provider to use (AWS)
#   2. Declare the input variables this project needs
#   3. Call the ec2_instance MODULE, passing in the right values based on
#      whichever Terraform WORKSPACE (dev/stage/prod) is currently active
# =============================================================================


# -----------------------------------------------------------------------------
# PROVIDER BLOCK
# -----------------------------------------------------------------------------
# Tells Terraform: "We are working with AWS, and all resources should be
# created in the us-east-1 (North Virginia) region."
# -----------------------------------------------------------------------------
provider "aws" {
  region = "us-east-1" # Change this if you want to deploy to a different AWS region
}


# -----------------------------------------------------------------------------
# VARIABLE: ami
# -----------------------------------------------------------------------------
# The AMI (Amazon Machine Image) ID to use when launching the EC2 instance.
# This has NO default value on purpose — it is provided via terraform.tfvars
# (see that file in this same folder) so it stays easy to change without
# editing this main.tf file directly.
# -----------------------------------------------------------------------------
variable "ami" {
  description = "The AMI ID to launch the EC2 instance from. Must be valid for the chosen AWS region (us-east-1)."
  type        = string
}


# -----------------------------------------------------------------------------
# VARIABLE: instance_type
# -----------------------------------------------------------------------------
# This is a MAP (a set of key-value pairs) where the KEY is the environment
# name (matching a Terraform WORKSPACE name) and the VALUE is the EC2
# instance size to use for that environment.
#
# WHY A MAP? Because we want DIFFERENT server sizes for different
# environments:
#   - dev   → small/cheap instance, since it's just for testing
#   - stage → medium instance, closer to production load for realistic testing
#   - prod  → large instance, since it needs to handle real user traffic
# -----------------------------------------------------------------------------
variable "instance_type" {
  description = "A map of environment names to EC2 instance types. The key must match a Terraform workspace name (dev, stage, or prod)."
  type        = map(string)

  default = {
    "dev"   = "t2.micro"   # Smallest/cheapest — fine for development and testing
    "stage" = "t2.medium"  # Medium size — used to test under more realistic load
    "prod"  = "t2.xlarge"  # Largest — used for real production traffic
  }
}


# -----------------------------------------------------------------------------
# MODULE CALL: ec2_instance
# -----------------------------------------------------------------------------
# This block "calls" the reusable module located in ./modules/ec2_instance
# and passes values INTO it. Think of this exactly like calling a function
# in a programming language — the module defines the logic ONCE, and we
# can call it multiple times (or, as here, once per workspace) with
# different arguments.
#
# ami           — passed straight through from our "ami" variable above
#                 (its value ultimately comes from terraform.tfvars)
#
# instance_type — uses the BUILT-IN lookup() function to find the correct
#                 instance size for the CURRENT workspace.
#
#                 lookup(MAP, KEY, DEFAULT) works like this:
#                   - MAP     = var.instance_type (our dev/stage/prod map above)
#                   - KEY     = terraform.workspace (the ACTIVE workspace name,
#                               e.g. "dev" if you ran `terraform workspace select dev`)
#                   - DEFAULT = "t2.micro" — used as a SAFETY NET. If you are in
#                               a workspace that doesn't exist in the map
#                               (e.g. the "default" workspace, or a typo'd
#                               workspace name), Terraform will NOT error out —
#                               it will safely fall back to the smallest,
#                               cheapest instance type instead.
#
# instance_name — passed through so the module can tag the instance with
#                 a clear, human-readable name that includes the project name.
# -----------------------------------------------------------------------------


module "ec2_instance" {
  source = "./modules/ec2_instance" # Path to our reusable module folder

  ami           = var.ami
  instance_type = lookup(var.instance_type, terraform.workspace, "t2.micro")
  instance_name = "myapp-server"
}


# -----------------------------------------------------------------------------
# OUTPUTS
# -----------------------------------------------------------------------------
# Outputs simply "pass through" the values returned by the module, making
# them visible in the terminal right after "terraform apply" finishes, and
# also retrievable anytime afterward via "terraform output".
# -----------------------------------------------------------------------------


output "instance_id" {
  description = "The ID of the EC2 instance created in the current workspace."
  value       = module.ec2_instance.instance_id
}

output "public_ip" {
  description = "The public IP address of the EC2 instance created in the current workspace."
  value       = module.ec2_instance.public_ip
}

output "instance_type_used" {
  description = "The EC2 instance type that was actually used for the current workspace."
  value       = module.ec2_instance.instance_type
}

output "current_workspace" {
  description = "The name of the Terraform workspace that was active during this apply."
  value       = terraform.workspace
}
