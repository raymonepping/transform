variable "region" {
  description = "Region to deploy resources"
  type        = string
  default     = "eu-north-1"
}

variable "project_name" {
  description = "Project name for tagging and identification"
  type        = string
}
