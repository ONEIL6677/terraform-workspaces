# =============================================================================
# modules/ec2_instance/main.tf
# -----------------------------------------------------------------------------
# This is the MODULE's main configuration file. A module is a REUSABLE,
# self-contained piece of Terraform code. This particular module's only
# job is to create ONE EC2 instance using whatever "ami" and
# "instance_type" values are passed into it from the ROOT main.tf.
#
# Because this logic lives in a module, we can reuse it for dev, stage,
# and prod environments WITHOUT duplicating this code three times.
# =============================================================================

# -----------------------------------------------------------------------------
# EC2 INSTANCE RESOURCE
# -----------------------------------------------------------------------------
# This block tells AWS: "create one virtual server (EC2 instance) using
# the AMI and instance type given to this module."
#
# var.ami           — comes from the variable declared in variables.tf,
#                      which is itself filled in by the ROOT main.tf
# var.instance_type — same idea; this value changes depending on which
#                      Terraform WORKSPACE (dev/stage/prod) is active
# -----------------------------------------------------------------------------
resource "aws_instance" "this" {
  ami           = var.ami            # Which operating system image to boot from
  instance_type = var.instance_type  # How powerful the server should be

  # ---------------------------------------------------------------------
  # TAGS
  # ---------------------------------------------------------------------
  # Tags are simple key-value labels attached to AWS resources. They make
  # resources easier to identify in the AWS Console, and are also used
  # by cost-tracking tools to show spend per environment.
  #
  # terraform.workspace is a BUILT-IN Terraform value that always equals
  # the name of the CURRENTLY SELECTED workspace (e.g. "dev", "stage",
  # "prod", or "default"). We use it here so every instance is
  # automatically labeled with the environment it belongs to — without
  # us needing to set this manually each time.
  # ---------------------------------------------------------------------
  tags = {
    Name        = "${var.instance_name}-${terraform.workspace}" # e.g. "ec2-instance-dev"
    Environment = terraform.workspace                            # e.g. "dev"
    ManagedBy   = "Terraform"
  }
}
