resource "aws_dynamodb_table" "sensors" {
   name = var.table_name
   billing_mode = "PAY_PER_REQUEST"
   hash_key = "sensor_id"

   attribute {
      name = "sensor_id"
      type = "S"
   }
}