



# AWS Jenkins CI/CD Setup

This project provides a complete CI/CD infrastructure with Jenkins on AWS, using Terraform for infrastructure provisioning and Ansible for server configuration.

## Architecture

- **Jenkins Controller**: EC2 instance with Jenkins and Docker
- **Deployment Server**: EC2 instance with Docker for application deployments
- **CI/CD Pipeline**: Jenkins pipeline for building, testing, and deploying Flask (or Django) applications

## Prerequisites

### Accounts & Tools
- AWS account with permissions to create EC2 instances
- SSH key (default: `skool-key`)
- Git
- Terraform >= 1.0
- Ansible >= 2.9
- Docker Hub account (for pushing images)

### AWS Configuration
```bash
aws configure
# Enter your Access Key ID, Secret Access Key, default region (us-east-1)
```

## Installation & Setup

### 1. Clone the repository
```bash
git clone https://github.com/otniel-tamini/aws-jenkins-cicd.git
cd aws-jenkins-cicd
```

### 2. SSH Key Setup
Ensure your private key is at `~/.ssh/skool-key.pem` with correct permissions:
```bash
chmod 400 ~/.ssh/skool-key.pem
```

### 3. Deploy Infrastructure
```bash
cd terraform
terraform init
terraform plan
terraform apply -auto-approve
```

Note the public IPs displayed in the output.

### 4. Ansible Configuration
Update `ansible/hosts.ini` with the IPs of the created instances:
```ini
[jenkins_servers]
jenkins ansible_host=<JENKINS_IP> ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/skool-key.pem

[deployment_servers]
deployment ansible_host=<DEPLOYMENT_IP> ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/skool-key.pem
```

### 5. Deploy Services
```bash
cd ansible
ansible-playbook -i hosts.ini -l jenkins_servers deploy_jenkins.yml
ansible-playbook -i hosts.ini -l deployment_servers prepare_deployment.yml
```

## Jenkins Configuration

### Initial Access
1. Open http://<JENKINS_IP>:8080
2. Use the admin password shown in the Ansible logs
3. Follow the setup wizard

### Docker Hub Credentials
1. In Jenkins: Manage Jenkins > Credentials > System > Global credentials
2. Add credentials of type "Username with password"
3. ID: `DOCKERHUB_CREDENTIALS`
4. Username: your Docker Hub username
5. Password: your Docker Hub token

### Pipeline Setup
1. Edit the `Jenkinsfile`:
  - Replace `your_dockerhub_username` with your Docker Hub username
  - Replace the Git repo URL with your own repo
  - Adjust the deployment IP if needed

2. Create a new Pipeline job:
  - New Item > Pipeline
  - Pipeline script from SCM
  - SCM: Git
  - Repository URL: https://github.com/otniel-tamini/aws-jenkins-cicd.git
  - Script Path: Jenkinsfile

## Pipeline Usage

The pipeline includes 5 stages:

1. **Checkout Code**: Retrieve source code
2. **Build Docker Image**: Build the Docker image
3. **Run Unit Tests**: Run tests inside the container
4. **Push to Docker Hub**: Push the image to Docker Hub
5. **Deploy to EC2**: Deploy on the deployment server

### Preparing Your Application
Your app should include:
- A `Dockerfile`
- Unit tests runnable with `pytest`
- A `requirements.txt` for Python dependencies

## Connecting to Instances

```bash
# Jenkins Controller
ssh -i ~/.ssh/skool-key.pem ec2-user@<JENKINS_IP>

# Deployment Server
ssh -i ~/.ssh/skool-key.pem ec2-user@<DEPLOYMENT_IP>
```


## Cleanup

To destroy all infrastructure:
```bash
cd terraform
terraform destroy -auto-approve
```

## Troubleshooting

### SSH Connection Error
- Check key permissions: `chmod 400 ~/.ssh/skool-key.pem`
- Add host keys: `ssh-keyscan -H <IP> >> ~/.ssh/known_hosts`

### Jenkins Not Starting
- Check logs: `sudo journalctl -u jenkins -f`
- Restart service: `sudo systemctl restart jenkins`

### Pipeline Failure
- Check Docker Hub credentials
- Ensure the Git repo is accessible
- Check Jenkins build logs

### Disk Issues
If you see disk warnings, the instance is configured with 50GB.

### Mount Temporary Storage on /tmp
To avoid space issues during builds or installs, mount a 2G temporary storage on `/tmp`:

```bash
sudo mount -t tmpfs -o size=2G tmpfs /tmp
```

To make this persistent, add the following line to `/etc/fstab`:

```bash
tmpfs /tmp tmpfs defaults,size=2G 0 0
```

## Customization

### Change AWS Region
Edit `terraform/main.tf`:
```hcl
provider "aws" {
  region = "eu-west-1"  # or another region
}
```

### Change Instance Type
Edit the `instance_type` variable in `terraform/main.tf`:
```hcl
variable "instance_type" {
  default = "t3.small"  # or another type
}
```

### Add Jenkins Plugins
Edit `ansible/deploy_jenkins.yml` to install additional plugins.

## Support

If you encounter issues:
1. Check Ansible/Terraform logs
2. Check GitHub issues
3. Verify your AWS configuration

## License

This project is MIT licensed.
