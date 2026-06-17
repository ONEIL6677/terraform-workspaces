# =============================================================================
# terraform.tfvars
# -----------------------------------------------------------------------------
# This file supplies VALUES for the variables declared in main.tf.
# Terraform automatically loads this file by name — you do NOT need to
# pass it manually with a -var-file flag.
#
# WHY USE A .tfvars FILE INSTEAD OF HARDCODING VALUES IN main.tf?
# It keeps configuration (the "what") separate from logic (the "how").
# If the AMI changes (which happens often — AWS regularly releases new
# AMI versions), you only need to update THIS file — main.tf never
# needs to change.
# =============================================================================

# The AMI ID to launch our EC2 instance from.
# This example uses an Amazon Linux 2023 AMI for the us-east-1 region.
#
# IMPORTANT: AMI IDs are REGION-SPECIFIC. If you change the "region" in
# the provider block inside main.tf, you MUST also update this AMI ID to
# a valid one for that new region, or "terraform apply" will fail.
# You can find valid AMI IDs in the EC2 Console under "AMI Catalog", or
# via: aws ec2 describe-images --owners amazon --filters "Name=name,Values=al2023-ami-*"


ami = "ami-053b0d53c279acc90"
