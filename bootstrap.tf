## Potrzebne do utworzenia tylko przy pierwszym inicie

# resource "aws_s3_bucket" "terraform_state" {
#   bucket = "t-state-bucket"
#   force_destroy = true

#   versioning {
#     enabled = true
#   }

#   lifecycle {
#     prevent_destroy = true
#   }
# }

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  lifecycle {
    prevent_destroy = true
  }
}