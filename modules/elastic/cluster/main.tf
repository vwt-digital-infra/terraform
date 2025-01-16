terraform {
  required_version = "~> 1.3"

  required_providers {
    ec = {
      source  = "elastic/ec"
      version = "0.10.0"
    }
  }

  backend "azurerm" {}
}

provider "ec" {}

data "ec_stack" "latest" {
  version_regex = var.ec_version
  region        = var.ec_region
}

resource "ec_deployment" "ec_cluster" {
  name                   = var.ec_deployment_name
  region                 = var.ec_region
  version                = data.ec_stack.latest.version
  deployment_template_id = var.ec_deployment_template_id

  elasticsearch {
    dynamic "topology" {
      for_each = {
        for index, topology in var.elasticsearch_topologies :
        index => topology
      }
      content {
        id         = topology.value.id
        size       = topology.value.size
        zone_count = topology.value.zone_count
      }
    }
  }

  kibana {
    dynamic "topology" {
      for_each = {
        for index, topology in var.kibana_topologies :
        index => topology
      }
      content {
        size       = topology.value.size
        zone_count = topology.value.zone_count
      }
    }
  }
}

resource "ec_deployment_traffic_filter" "traffic_filter" {
  name   = var.traffic_filter_name
  region = var.ec_region
  type   = var.traffic_filter_type

  dynamic "rule" {
    for_each = toset(var.traffic_filter_sources)
    content {
      source = rule.key
    }
  }
}

resource "ec_deployment_traffic_filter_association" "traffic_filter_association" {
  traffic_filter_id = ec_deployment_traffic_filter.traffic_filter.id
  deployment_id     = ec_deployment.ec_cluster.id
}
