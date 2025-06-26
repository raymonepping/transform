variable "project_name" {
  description = "Project name for tagging or naming"
  type        = string
  default     = "transform"
}

variable "environment" {
  description = "Environment identifier (e.g., dev, prod)"
  type        = string
  default     = "dev"
}
