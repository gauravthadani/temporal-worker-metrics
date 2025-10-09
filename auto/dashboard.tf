resource "grafana_data_source" "arbitrary-data" {
  type = "prometheus"
  name = "prometheus"
  url = "http://prometheus:9090"
}

resource "grafana_data_source" "cloud-metrics" {
  type = "prometheus"
  name = "prometheus-cloud"
  url = "https://a2dd6.tmprl.cloud/prometheus"

  json_data_encoded = jsonencode({
    httpMethod = "POST"
    serverName: "a2dd6.tmprl.cloud"
    tlsAuth: true
    tlsAuthWithCACert: false
    tlsSkipVerify: false
  })

    secure_json_data_encoded = jsonencode({
    "tlsClientCert" = local.certs.cert
    "tlsClientKey"  = local.certs.key
  })
}

resource "grafana_folder" "test" {
  title = "Temporal Dashboards"
  uid   = "some-unique-id"
}

resource "grafana_dashboard" "temporal_dashboards" {
  for_each = local.json_file_details
  folder = grafana_folder.test.uid
  config_json = each.value.content
}