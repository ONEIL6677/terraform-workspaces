# =============================================================================
# modules/ec2_instance/variables.tf
# -----------------------------------------------------------------------------
# This file declares the INPUT variables that this module accepts.
# Think of a module like a function in programming — these variables are
# its "parameters". The ROOT main.tf (one level up) will pass values INTO
# this module for these variables.
# =============================================================================

# -----------------------------------------------------------------------------
# AMI VARIABLE
# -----------------------------------------------------------------------------
# AMI = Amazon Machine Image. This is the "template" operating system image
# AWS uses to launch your EC2 instance (e.g. a specific Ubuntu or Amazon
# Linux version). There is NO default here — the calling code (root main.tf)
# MUST supply this value, because AMI IDs are region-specific and change
# over time, so we never want to silently fall back to a hardcoded default.
# -----------------------------------------------------------------------------


variable "ami" {
  description = "The AMI ID to use for launching the EC2 instance. This is region-specific."
  type        = string
}


# -----------------------------------------------------------------------------
# INSTANCE TYPE VARIABLE
# -----------------------------------------------------------------------------
# This defines the SIZE of the server (how much CPU/RAM it has).
# e.g. "t2.micro" = 1 vCPU, 1GB RAM (Free Tier eligible)
#      "t2.xlarge" = 4 vCPU, 16GB RAM (much more powerful, costs more)
#
# We give this a SENSIBLE DEFAULT ("t2.micro") so if the calling code
# forgets to pass a value, the module still works safely with the
# smallest, cheapest instance type instead of failing.
# -----------------------------------------------------------------------------


variable "instance_type" {
  description = "The EC2 instance type/size to launch (e.g. t2.micro, t2.medium, t2.xlarge)."
  type        = string
  default     = "t2.micro"
}


# -----------------------------------------------------------------------------
# INSTANCE NAME VARIABLE
# -----------------------------------------------------------------------------
# A human-friendly name for this instance, shown as the "Name" tag in the
# AWS Console. We include the workspace name in this tag later so it's
# instantly obvious which environment (dev/stage/prod) an instance belongs to.
# -----------------------------------------------------------------------------


variable "instance_name" {
  description = "The value used for the 'Name' tag on the EC2 instance."
  type        = string
  default     = "ec2-instance"
}
