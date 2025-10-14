locals {
  grafana_url    = var.grafana_url
  prometheus_url = var.prometheus_url

  search_directory = "${path.module}/../dashboards/"
  json_files       = fileset(local.search_directory, "**/*.json")
  json_file_content_map = {
    for file_path in local.json_files :
    file_path => file("${local.search_directory}/${file_path}")
  }

  json_file_content_map_basename = {
    for file_path in local.json_files :
    basename(file_path) => file("${local.search_directory}/${file_path}")
  }

  json_file_details = {
    for file_path in local.json_files :
    file_path => {
      full_path = file_path
      filename  = basename(file_path)
      directory = dirname(file_path)
      content   = file("${local.search_directory}/${file_path}")
      size      = length(file("${local.search_directory}/${file_path}"))
    }
  }


  certs = {
    cert = file("${path.module}/../temporal-certs/client.pem")
    key  = file("${path.module}/../temporal-certs/client.key")
  }
}

output "found_json_files" {
  value = local.json_file_details
}
