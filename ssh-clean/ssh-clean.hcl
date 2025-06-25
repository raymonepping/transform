job "ssh-clean" {
  datacenters = ["dc1"]

  group "ssh-clean-group" {
    network {
      
      port "ssh" {
        static = 2222
        to     = 22
      }
    }

    task "ssh-clean-task" {
      driver = "docker"

      config {
        image = "repping/ssh-clean"
        ports = ["ssh"]
        volumes = []
        privileged = true
        cap_add = ["IPC_LOCK"]
      }

      env = {

      }

      resources {
        cpu    = 500
        memory = 256
      }
    }
  }
}
