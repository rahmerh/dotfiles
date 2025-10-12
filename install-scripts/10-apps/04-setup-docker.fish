#!/usr/bin/env fish
source install-scripts/library/print-utils.fish

print_info "Configuring docker"

sudo groupadd docker
sudo usermod -aG docker $USER
sudo nvidia-ctk runtime configure --runtime=docker

sudo systemctl enable --now docker.service

print_success Done
