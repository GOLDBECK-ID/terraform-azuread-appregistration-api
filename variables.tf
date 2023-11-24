variable "client_id" {
  description = ""
  type        = string
  default     = ""
}

variable "client_secret" {
  description = ""
  type        = string
  default     = ""
}

variable "tenant_id" {
  description = ""
  type        = string
  default     = ""
}

variable "authorized_app_id" {
  description = "Authorized client application in settings 'Expose an API'"
  default     = ""
}

variable "name" {
  description = ""
  default     = ""
}

variable "owners" {
  description = "IDs of the owner"
  type = list(string)
  default = [ "" ]
}

variable "sign_in_audience" {
  type = string
  default = "sign_in_audience"
}

variable "environment" {
  description = ""
  default     = ""
}

variable "client_secret_expiration_date" {
  description = "the expiration date used for secrets etc."
  type        = string
  default     = "2099-12-31T23:59:59Z"
}

variable "is_frontend" {
  description = "Distinguish between frontend and backend registration"
  type        = bool
  default     = false
}

variable "spa_redirect_uris" {
  type    = list(string)
  default = []
}

variable "required_resource_access" {
  description = "Required resource access for this application."
  type = list(
    object({
      resource_app_id = string
      resource_access = list(
        object({
          id   = string
          type = string
      }))
  }))
}
variable "web_redirect_uris" {
  type    = list(string)
  default = []
}

variable "required_resource_access_map" {
  type = list(object({
    resource_app_id = string
    resource_access_list = list(object({
      resource_access_id   = string
      resource_access_type = string
    }))
  }))
  default = []
}