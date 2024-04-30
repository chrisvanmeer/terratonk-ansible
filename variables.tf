## GENERIC

variable "project_name" {
  description = "The name of the Google project"
  # no default, so you will be prompted
}

variable "region" {
  description = "The Google region of your choice"
  default     = "europe-west4"
}

variable "zone" {
  description = "The Google zone of your choice within the region"
  default     = "europe-west4-a"
}

## CONTROLLER

variable "ansible_controller_ssh_user" {
  default = "ansible"
}

variable "ansible_controller_ssh_pub_key_file" {
  default = "~/.ssh/id_ed25519.pub"
}

variable "ansible_controller_ssh_priv_key_file" {
  default = "~/.ssh/id_ed25519"
}

variable "ansible_controller_name" {
  description = "Name of the Ansible Controller"
  default     = "controller"
}

variable "ansible_controller_image" {
  description = "The image for running the Ansible Controller"
  default     = "rocky-linux-9-v20240415"
}

variable "ansible_controller_machine_type" {
  description = "The machine type for running the Ansible Controller"
  default     = "n1-standard-1"
}

## WINDOWS HOSTS

variable "ansible_windows_hosts_image" {
  description = "The image for running the Ansible Windows hosts"
  default     = "windows-cloud/windows-2019"
}

variable "ansible_windows_hosts_machine_type" {
  description = "The machine type for running the Ansible Windows hosts"
  default     = "n1-standard-1"
}

variable "ansible_windows_hosts_admin_username" {
  description = "The admin username of the Windows hosts"
  default     = "admini"
}

variable "ansible_windows_hosts" {
  description = "List of Ansible Windows host names"
  default = [
    "server01",
    "server02"
  ]
}
