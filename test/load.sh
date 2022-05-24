cat kubernetes_e2e_images_v1.20.0.tar.gz | docker load
docker tag sonobuoy/systemd-logs:v0.4 registry.hub.docker.com/sonobuoy/systemd-logs:v0.4
docker tag sonobuoy/sonobuoy:v0.55.0 registry.hub.docker.com/sonobuoy/sonobuoy:v0.55.0