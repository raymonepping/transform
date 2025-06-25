variable "project_name" { type = string }
variable "environment"  { type = string }
variable "region"       { 
  type = string  
  default = "eu-north-1" 
}
variable "key_name" {
  type = string
  default = "transformation_key"
}
