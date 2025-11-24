# GEMINI.md

## Project Overview

This project provides a multi-architecture Docker image for network troubleshooting. It's based on Alpine Linux and includes a wide range of command-line tools for network diagnostics, as well as an Nginx web server. The project also provides a Fedora-based variant. The Docker image is designed to be used in various environments, including standalone Docker, Kubernetes, and OpenShift.

The core of the project is the `Dockerfile` that builds the image, installing tools like `curl`, `ping`, `traceroute`, `tcpdump`, and `nmap`. An `entrypoint.sh` script dynamically configures the container on startup, setting up an `index.html` page with container details and allowing for customizable HTTP/HTTPS ports via environment variables.

The Nginx web server runs by default to keep the container alive and serves a simple status page. This makes it easy to run the container and then `exec` into it for troubleshooting.

## Building and Running

### Building the Docker Image

To build the Docker image locally, use the following command:

```bash
docker build -t local/network-multitool .
```

### Running the Docker Image

To run the container:

```bash
# Run in detached mode
docker run -d wbitt/network-multitool

# Exec into the running container
docker exec -it <container-name> /bin/bash
```

To run with custom ports:

```bash
docker run -e HTTP_PORT=8080 -e HTTPS_PORT=8443 -p 8080:8080 -p 8443:8443 -d wbitt/network-multitool
```

### Kubernetes

A `DaemonSet` is provided to run the multitool on all nodes in a Kubernetes cluster:

```bash
kubectl apply -f kubernetes/multitool-daemonset.yml
```

This will run the multitool on each node with host networking enabled.

## Development Conventions

*   The project follows a "minimal but useful" philosophy, including only the most essential tools to keep the image size small.
*   The `Dockerfile` is well-documented, with packages listed in alphabetical order for readability.
*   The `entrypoint.sh` script provides flexibility for running the container in different scenarios.
*   The Nginx configuration is set up to forward logs to `stdout` and `stderr`, which is a best practice for containerized applications.
*   Contributions are welcome, but should be for "absolutely necessary" tools that are small and have a large number of use cases.
