variable "cluster_name" { type = string }
variable "addon_name" { type = string }
variable "addon_version" { type = string }
variable "service_account_role_arn" {
	type    = string
	default = ""
}
variable "resolve_conflicts" {
	type    = string
	default = "OVERWRITE"
}
variable "configuration_values" {
	type    = string
	default = ""
}
variable "tags" {
	type    = map(string)
	default = {}
}
