# --- CloudFront in front of the ALB ----------------------------------------
# Gives a free, valid HTTPS URL on *.cloudfront.net (works on phones, which
# force HTTPS). CloudFront terminates TLS with its default certificate and
# forwards to the ALB over HTTP. Caching is disabled because the app is dynamic.

resource "aws_cloudfront_distribution" "app" {
  enabled     = true
  comment     = "ShopFront - HTTPS front door for the ALB"
  price_class = "PriceClass_100" # US/Canada/Europe edges — cheapest

  origin {
    domain_name = aws_lb.main.dns_name
    origin_id   = "shopfront-alb"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only" # ALB only listens on HTTP
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = "shopfront-alb"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]

    # Managed policies: disable caching + forward viewer request attributes so
    # the dynamic API/pages always hit the origin.
    cache_policy_id          = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" # Managed-CachingDisabled
    origin_request_policy_id = "216adef6-5c7f-47e4-b989-5492eafa07d3" # Managed-AllViewer
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true # free HTTPS on *.cloudfront.net
  }

  tags = local.tags
}

output "https_url" {
  description = "Phone-friendly HTTPS URL via CloudFront."
  value       = "https://${aws_cloudfront_distribution.app.domain_name}"
}
