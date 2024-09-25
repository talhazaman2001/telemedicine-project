# Create Cognito User Pool
resource "aws_cognito_user_pool" "telemedicine_user_pool" {
    name = "telemedicine-user-pool"

    password_policy {
        minimum_length = 8
        require_lowercase = true
        require_uppercase = true
        require_numbers = true
        require_symbols = false
    }

    auto_verified_attributes = ["email"]

    schema {
        attribute_data_type = "String"
        name = "email"
        required = true
        mutable = false
    }
}

# Create Cognito User Pool Client
resource "aws_cognito_user_pool_client" "telemedicine_user_pool_client" {
    name = "telemedicine-user-pool-client"
    user_pool_id = aws_cognito_user_pool.telemedicine_user_pool.id
    generate_secret = false

    allowed_oauth_flows = ["code"]
    allowed_oauth_scopes = ["email", "openid", "profile"]
    allowed_oauth_flows_user_pool_client = true

    explicit_auth_flows = ["ALLOW_USER_SRP_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
    callback_urls = ["https://your-app.url.com/callback"] # Insert APP URL
    logout_urls = ["https://your-app.url.com/logout"]
}

# Create Cognito identity pool
resource "aws_cognito_identity_pool" "telemedicine_identity_pool" {
    identity_pool_name = "telemedicine-identity-pool"
    allow_unauthenticated_identities = false

    cognito_identity_providers {
      provider_name = "cognito-idp.eu-west-2.amazonaws.com/${aws_cognito_user_pool.telemedicine_user_pool.id}"
      client_id = aws_cognito_user_pool_client.telemedicine_user_pool_client.id
    }
}


# IAM Roles for Cognito Identity Pool (authenticated and unauthenticated)
resource "aws_iam_role" "cognito_authenticated_role" {
    name = "CognitoTelemedicineAuthenticatedRole"

    assume_role_policy = jsonencode({
        Version = "2012-10-17",
        Statement = [{
            Effect = "Allow",
            Principal = {
                Federated = "coginto-identity.amazonaws.com"
            },
            Action = "sts:AssumeRoleWithWebIdentity",
            Condition = {
                "StringEquals": {
                    "cognito-identity.amazonaws.com:aud": "${aws_cognito_identity_pool.telemedicine_identity_pool.id}"
                },
                "ForAnyValue:StringLike": {
                    "cognito-idenity.amazonaws.com:amr" : "authenticated"
                }
            }
        }]
    })
}

resource "aws_iam_role" "cognito_unauthenticated_role" {
  name = "CognitoTelemedicineUnauthenticatedRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Federated = "cognito-identity.amazonaws.com"
      },
      Action = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        "StringEquals": {
          "cognito-identity.amazonaws.com:aud": "${aws_cognito_identity_pool.telemedicine_identity_pool.id}"
        },
        "ForAnyValue:StringLike": {
          "cognito-identity.amazonaws.com:amr": "unauthenticated"
        }
      }
    }]
  })
}

# Attach roles to Cognito identity pool
resource "aws_cognito_identity_pool_roles_attachment" "telemedicine_identity_pool_roles" {
    identity_pool_id = aws_cognito_identity_pool.telemedicine_identity_pool.id

    roles = {
        "authenticated" = aws_iam_role.cognito_authenticated_role.arn
        "unauthenticated" = aws_iam_role.cognito_unauthenticated_role.arn
    }
}

output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.telemedicine_user_pool.id
}

output "cognito_user_pool_client_id" {
  value = aws_cognito_user_pool_client.telemedicine_user_pool_client.id
}

output "cognito_identity_pool_id" {
  value = aws_cognito_identity_pool.telemedicine_identity_pool.id
}
