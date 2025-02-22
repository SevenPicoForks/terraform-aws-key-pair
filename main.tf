locals {
  enabled = module.context.enabled
  public_key_filename = format(
    "%s/%s",
    var.ssh_public_key_path,
    coalesce(var.ssh_public_key_file, join("", [module.context.id, var.public_key_extension]))
  )

  private_key_filename = format(
    "%s/%s%s",
    var.ssh_public_key_path,
    module.context.id,
    var.private_key_extension
  )
}

resource "aws_key_pair" "imported" {
  count      = local.enabled && var.generate_ssh_key == false ? 1 : 0
  key_name   = module.context.id
  public_key = file(local.public_key_filename)
  tags       = module.context.tags
}

resource "tls_private_key" "default" {
  count     = local.enabled && var.generate_ssh_key == true ? 1 : 0
  algorithm = var.ssh_key_algorithm
}

resource "aws_key_pair" "generated" {
  count      = local.enabled && var.generate_ssh_key == true ? 1 : 0
  depends_on = [tls_private_key.default]
  key_name   = module.context.id
  public_key = tls_private_key.default[0].public_key_openssh
  tags       = module.context.tags
}

resource "local_file" "public_key_openssh" {
  count      = local.enabled && var.generate_ssh_key && var.write_ssh_key_to_file == true ? 1 : 0
  depends_on = [tls_private_key.default]
  content    = tls_private_key.default[0].public_key_openssh
  filename   = local.public_key_filename
}

resource "local_sensitive_file" "private_key_pem" {
  count           = local.enabled && var.generate_ssh_key && var.write_ssh_key_to_file == true ? 1 : 0
  depends_on      = [tls_private_key.default]
  content         = tls_private_key.default[0].private_key_pem
  filename        = local.private_key_filename
  file_permission = "0600"
}
