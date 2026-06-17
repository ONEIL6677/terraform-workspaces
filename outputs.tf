# =============================================================================
# modules/ec2_instance/outputs.tf
# -----------------------------------------------------------------------------
# OUTPUTS let a module "return" values back to whatever code called it
# (in our case, the ROOT main.tf). Without outputs, the root configuration
# would have NO WAY of knowing the instance ID or IP address of the
# server the module just created — that information would be "trapped"
# inside the module.
# =============================================================================

# -----------------------------------------------------------------------------
# INSTANCE ID OUTPUT
# -----------------------------------------------------------------------------
# Exposes the unique AWS-assigned ID of the instance (e.g. "i-0abc123def456")
# so the root configuration (or a person running `terraform output`) can
# see exactly which instance was created.
# -----------------------------------------------------------------------------


output "instance_id" {
  description = "The unique ID AWS assigned to this EC2 instance."
  value       = aws_instance.this.id
}


# -----------------------------------------------------------------------------
# PUBLIC IP OUTPUT
# -----------------------------------------------------------------------------
# Exposes the public IP address of the instance, if it has one. This is
# what you would use to SSH into the server or access a web app running
# on it.
# -----------------------------------------------------------------------------
output "public_ip" {
  description = "The public IP address of the EC2 instance (if assigned)."
  value       = aws_instance.this.public_ip
}

# -----------------------------------------------------------------------------
# INSTANCE TYPE OUTPUT
# -----------------------------------------------------------------------------
# Exposes which instance type was actually used. This is especially useful
# here because the instance type CHANGES depending on which workspace is
# active (dev/stage/prod) — this output lets us quickly confirm the
# correct size was picked for the current workspace.
# -----------------------------------------------------------------------------


output "instance_type" {
  description = "The EC2 instance type that was launched."
  value       = aws_instance.this.instance_type
}
