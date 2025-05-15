
This project uses Terraform to provision Docker-based infrastructure
across three environments (dev, staging, prod) for Ansible automation testing.

Each environment consists of:
- A dedicated Docker network.
- 8 Debian containers, each with a static IP within the network.
- openssh-server, systemd, and sudo installed.
- An 'ansible_user' with a specified password for SSH access.
- sshd running in the foreground to keep the container alive.

## Project Structure

.
├── main.tf
├── variables.tf
├── terraform.tfvars
├── modules/
│ └── environment_servers/
│ ├── main.tf
│ └── variables.tf
└── README.md



## Requirements

- Docker installed and running.
- Terraform installed.

## Usage

1.  Navigate to the project directory:
    ```bash
    cd path/to/Task4-AnsibleInfra
    ```
2.  Initialize Terraform and download providers/modules:
    ```bash
    terraform init
    ```
3.  Review the planned infrastructure changes:
    ```bash
    terraform plan
    ```
4.  Apply the changes to create the infrastructure:
    ```bash
    terraform apply
    ```
    Confirm with `yes` when prompted.

5.  Verify containers are running and have IPs:
    ```bash
    docker ps
    # Note the container names (e.g., dev-server-0, staging-server-5)
    docker inspect <container_name> | grep IPAddress
    # Check the assigned IP (e.g., "IPAddress": "172.20.0.10")
    ```

6.  **Test SSH access (Optional but recommended for Ansible prep):**
    From your host machine, you should be able to SSH into the containers using the assigned IPs and the specified SSH user/password (e.g., `ssh ansible_user@172.20.0.10`).

7.  Destroy the created infrastructure:
    ```bash
    terraform destroy
    ```
    Confirm with `yes` when prompted.

## Notes

- The containers run sshd as the primary process. systemd is installed but not running as PID 1 in the standard Docker way.
- Password-based SSH authentication is used for simplicity in this exercise. In production, always use SSH keys.