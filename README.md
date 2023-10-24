# NGINX Dynamic Configuration Docker

This README provides an in-depth understanding of the Bash script `script.sh`, its interaction with Docker container labels, and how it dynamically configures NGINX. Additionally, it outlines the Dockerfile used to create a Docker image with the dynamic configuration feature.

## Script Overview

The `script.sh` is a Bash script that automates NGINX configuration adjustments based on Docker container labels. These labels provide metadata for the script to customize NGINX server blocks for each running container. The script meticulously manages these labels, ensuring NGINX serves multiple web applications with unique settings. Let's explore how the script utilizes Docker container labels:

### Docker Container Labels

The script employs several key Docker container labels to customize NGINX server blocks for each container. These labels help determine the behavior of the NGINX configuration. Here's an overview of the labels and their purpose:

- **`ingress-host`**: Specifies the primary host or domain name to be associated with the NGINX server block.
  - **Usage**: Enables each container to have a unique domain or host name. Required for proper configuration.

- **`cert-name`**: Defines the name of the SSL certificate and key to be used for secure connections (HTTPS).
  - **Usage**: Allows each container to use distinct SSL certificates and keys.
  - **Fallback**: When not provided, the script uses default certificate paths.

- **`www_redirect`**: Controls whether www redirection should be enabled for the associated domain.
  - **Usage**: Enables or disables www-to-non-www or non-www-to-www redirection based on container requirements.

- **`additional_non_www_ingress_host`**: Specifies an additional host or domain name for an extra NGINX server block.
  - **Usage**: Facilitates the creation of multiple server blocks, each handling a unique domain.
  - **Fallback**: If not provided, no additional server block is created.

- **`additional_non_www_cert_name`**: Defines the name of the SSL certificate and key for the additional server block.
  - **Usage**: Permits separate SSL certificates for different domains.
  - **Fallback**: If not provided, the script uses the default certificate paths.

- **`additional_non_www_service_name` and `additional_non_www_container_port`**: Specify the name of a service and the container port to which requests for the additional domain should be forwarded.
  - **Usage**: Offers flexibility in routing requests to different backend services.
  - **Fallback**: If not provided, requests are not proxied to the additional domain.

### Script Behavior

The script utilizes these Docker container labels to dynamically generate NGINX server blocks and tailor various settings:

- **SSL Configuration**: When `cert-name` is provided, the script configures SSL settings with the specified certificate and key. In the absence of this label, default SSL paths are used.

- **www Redirection**: If `www_redirect` is set to "true," the script creates NGINX configuration with www redirection. Otherwise, redirection is not applied.

- **Additional Server Blocks**: When `additional_non_www_ingress_host` is provided, an extra server block is created for the domain. This allows the script to manage multiple domains efficiently.

- **Error Handling**: The script accounts for situations where certain label values are missing or not provided. It gracefully handles these cases, ensuring NGINX can still function with appropriate fallbacks.

- **Configuration Updates**: The script continually monitors for changes in NGINX configuration. When changes are detected, it updates the NGINX configuration file and initiates an NGINX reload to apply the new settings.

- **Logging**: The script provides detailed logs about configuration changes and NGINX reloads for effective monitoring.

- **Sleep Period**: To manage system resources effectively, the script includes a brief 10-second sleep period before the next iteration.

### NGINX Configuration Updates

Using the Docker container labels, the script dynamically generates NGINX server blocks, configuring settings like SSL, www redirection, and proxy pass directives. This dynamic approach streamlines the management of multiple domains, SSL certificates, and custom settings within a single NGINX instance.

### Configuration Changes and Updates

The script continuously checks for changes in NGINX configuration. When changes are detected, it updates the NGINX configuration file and triggers an NGINX reload. This ensures that the changes take effect.

### Logging

The script provides logging information about configuration changes and NGINX reloads.

### Sleep Period

A 10-second sleep period is incorporated before the script's next iteration.

## Dockerfile

The Dockerfile is used to build a Docker image that runs NGINX with the dynamic configuration script. It includes the following key components:

- **Base Image**: Utilizes the official NGINX Docker image (`nginx:latest`) as the starting point.

- **System Updates and Dependencies**: Updates system package lists and installs necessary dependencies (`jq` and `docker.io`) within the container.

- **Working Directory**: Sets the working directory within the container to `/app`.

- **File Copying**: Copies essential files, such as SSL certificates, the dynamic configuration script (`script.sh`), NGINX configuration (`nginx.conf`), and an entry point script (`entrypoint.sh`) into the container.

- **Permissions**: Sets executable permissions for the `script.sh` and `entrypoint.sh` scripts.

- **Exposed Ports**: Exposes ports 80 (HTTP) and 443 (HTTPS) to allow incoming web traffic.

- **Entry Point**: Configures the entry point of the container to be the `entrypoint.sh` script, which manages the startup of NGINX and other services.

## Usage

To use this dynamic NGINX configuration setup:

1. Build the Docker image based on the provided Dockerfile.
2. Create and run containers from the image while ensuring that the necessary Docker container labels are set according to your requirements.
3. The `script.sh` script will continuously inspect containers and update the NGINX configuration dynamically based on the specified labels.

This approach simplifies the management of NGINX configurations, making it a valuable solution for scenarios where multiple domains, SSL certificates, and custom settings are required for different web applications or services running within Docker containers.

## Pulling the Docker Image

You can also pull the Docker image directly from Docker Hub using the following command:

```bash
docker pull docker.io/blackdocs/ingress-controller:latest-stable
```
