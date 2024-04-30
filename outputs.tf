output "ansible_controller_ip" {
  value = google_compute_instance.ansible_controller.network_interface.0.access_config.0.nat_ip
}
output "ansible_host_ips" {
  value = formatlist(
    "%s: %s",
    google_compute_instance.ansible_windows_hosts[*].name,
    google_compute_instance.ansible_windows_hosts[*].network_interface.0.access_config.0.nat_ip
  )
}
