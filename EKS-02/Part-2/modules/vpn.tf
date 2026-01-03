# ========= Generating Certificates for VPN =========


# =====   CA Certificate   =====
resource "tls_private_key" "ca_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}


resource "tls_self_signed_cert" "ca_cert" {
  private_key_pem = tls_private_key.ca_key.private_key_pem

  subject {
    common_name  = "VPN Root CA"
    organization = "test"
  }

  validity_period_hours = 8600 # 10 years
  is_ca_certificate     = true

  allowed_uses = [
    "cert_signing",
    "crl_signing",
    "digital_signature",
    "key_encipherment"
  ]
}


# =====   Server Certificate   =====

resource "tls_private_key" "server_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "server_csr" {
  private_key_pem = tls_private_key.server_key.private_key_pem

  subject {
    common_name  = "server.${var.vpn_domain}"
    organization = "test"
  }

  dns_names = [
    "server.${var.vpn_domain}",
    "vpn.${var.vpn_domain}"
  ]
}

resource "tls_locally_signed_cert" "server_cert" {
  cert_request_pem   = tls_cert_request.server_csr.cert_request_pem
  ca_private_key_pem = tls_private_key.ca_key.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca_cert.cert_pem

  validity_period_hours = 8600 # 1 year

  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "server_auth",
    "client_auth",
  ]

  set_subject_key_id = true
}


# =====   Client Certificate   =====

resource "tls_private_key" "client_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "client_csr" {
  private_key_pem = tls_private_key.client_key.private_key_pem

  subject {
    common_name  = "client1.${var.vpn_domain}"
    organization = "test"
  }

  dns_names = ["client1.${var.vpn_domain}"]
}


resource "tls_locally_signed_cert" "client_cert" {
  cert_request_pem   = tls_cert_request.client_csr.cert_request_pem
  ca_private_key_pem = tls_private_key.ca_key.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca_cert.cert_pem

  validity_period_hours = 8600

  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "client_auth",
  ]

  set_subject_key_id = true
}


# ============= Importing Certificates to ACM =============

resource "aws_acm_certificate" "server_cert" {
  private_key       = tls_private_key.server_key.private_key_pem
  certificate_body  = tls_locally_signed_cert.server_cert.cert_pem
  certificate_chain = tls_self_signed_cert.ca_cert.cert_pem

  tags = {
    Key = "server-cred"
  }

}

resource "aws_acm_certificate" "ca_cert" {
  private_key      = tls_private_key.ca_key.private_key_pem
  certificate_body = tls_self_signed_cert.ca_cert.cert_pem

  tags = {
    Key = "ca-cred"
  }
}



# ============= Creating VPN ===============

resource "aws_ec2_client_vpn_endpoint" "vpn" {
    description = "Client VPN Endpoint"
    server_certificate_arn = aws_acm_certificate.server_cert.arn
    client_cidr_block = var.client_cidr_block
    vpc_id = aws_vpc.vpc.id
    split_tunnel = true

    authentication_options {
      type = "certificate-authentication"
      root_certificate_chain_arn = aws_acm_certificate.ca_cert.arn
    }

    connection_log_options {
      enabled = true
      cloudwatch_log_group = aws_cloudwatch_log_group.vpn_logs.name
      cloudwatch_log_stream = aws_cloudwatch_log_stream.vpn_logs.name
    }

    session_timeout_hours = 8

    client_login_banner_options {
      enabled = true
      banner_text = "This VPN is for authorized users only."
    }
}


# ============= Associating VPN with Subnet ===============
resource "aws_ec2_client_vpn_network_association" "vpn_subnet" {
    # count = var.private_subnet_count
    client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
    subnet_id = aws_subnet.private_subnet[0].id
}

# ============= Authorization Rule ===============

resource "aws_ec2_client_vpn_authorization_rule" "vpn_auth_rule" {
    count = var.private_subnet_count
    client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
    target_network_cidr = var.private_subnet_cidrs[count.index]
    authorize_all_groups = true
}

# ============= CloudWatch Logs for VPN ===============

resource "aws_cloudwatch_log_group" "vpn_logs" {
    # encrypted by default
    name              = "/aws/vpn/${var.vpn_domain}"
    retention_in_days = 2192 # 6 years
}
resource "aws_cloudwatch_log_stream" "vpn_logs" {
  name           = "vpn-connection-logs"
  log_group_name = aws_cloudwatch_log_group.vpn_logs.name
}


output "client_key" {
  value     = tls_private_key.client_key.private_key_pem
  sensitive = true
}
output "client_cert" {
  value = tls_locally_signed_cert.client_cert.cert_pem
}
