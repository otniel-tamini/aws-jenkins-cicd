# AWS Jenkins CI/CD Setup

Ce projet fournit une infrastructure complète CI/CD avec Jenkins sur AWS utilisant Terraform pour l'infrastructure et Ansible pour le déploiement.

## Architecture

- **Jenkins Controller** : Instance EC2 avec Jenkins et Docker
- **Serveur de Déploiement** : Instance EC2 avec Docker pour les déploiements
- **Pipeline CI/CD** : Pipeline Jenkins pour build, test et déploiement d'applications Flask

## Prérequis

### Comptes et Outils
- Compte AWS avec permissions pour créer des instances EC2
- Clé SSH (par défaut `skool-key`)
- Git
- Terraform >= 1.0
- Ansible >= 2.9
- Docker Hub account (pour le push des images)

### Configuration AWS
```bash
aws configure
# Entrez votre Access Key ID, Secret Access Key, région par défaut (us-east-1)
```

## Installation et Configuration

### 1. Cloner le dépôt
```bash
git clone https://github.com/otniel-tamini/aws-jenkins-cicd.git
cd aws-jenkins-cicd
```

### 2. Configuration des clés SSH
Assurez-vous que votre clé privée est dans `~/.ssh/skool-key.pem` avec les bonnes permissions :
```bash
chmod 400 ~/.ssh/skool-key.pem
```

### 3. Déploiement de l'infrastructure
```bash
cd terraform
terraform init
terraform plan
terraform apply -auto-approve
```

Notez les IPs publiques affichées en output.

### 4. Configuration Ansible
Mettez à jour `ansible/hosts.ini` avec les IPs des instances créées :
```ini
[jenkins_servers]
jenkins ansible_host=<JENKINS_IP> ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/skool-key.pem

[deployment_servers]
deployment ansible_host=<DEPLOYMENT_IP> ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/skool-key.pem
```

### 5. Déploiement des services
```bash
cd ansible
ansible-playbook -i hosts.ini -l jenkins_servers deploy_jenkins.yml
ansible-playbook -i hosts.ini -l deployment_servers prepare_deployment.yml
```

## Configuration Jenkins

### Accès initial
1. Ouvrez http://<JENKINS_IP>:8080
2. Utilisez le mot de passe admin affiché dans les logs Ansible
3. Suivez l'assistant de configuration

### Configuration des credentials Docker Hub
1. Dans Jenkins : Manage Jenkins > Credentials > System > Global credentials
2. Ajoutez des credentials de type "Username with password"
3. ID : `dockerhub-login`
4. Username : votre username Docker Hub
5. Password : votre token Docker Hub

### Configuration du pipeline
1. Modifiez le `Jenkinsfile` :
   - Remplacez `your_dockerhub_username` par votre username Docker Hub
   - Remplacez l'URL du repo Git par votre repo
   - Ajustez l'IP de déploiement si nécessaire

2. Créez un nouveau job Pipeline :
   - New Item > Pipeline
   - Pipeline script from SCM
   - SCM : Git
   - Repository URL : https://github.com/otniel-tamini/aws-jenkins-cicd.git
   - Script Path : Jenkinsfile

## Utilisation du Pipeline

Le pipeline comprend 5 étapes :

1. **Checkout Code** : Récupération du code source
2. **Build Docker Image** : Construction de l'image Docker
3. **Run Unit Tests** : Exécution des tests dans le conteneur
4. **Push to Docker Hub** : Push de l'image vers Docker Hub
5. **Deploy to EC2** : Déploiement sur le serveur de déploiement

### Préparation de votre application
Votre application doit avoir :
- Un `Dockerfile`
- Des tests unitaires exécutables avec `pytest`
- Un `requirements.txt` pour Python

## Connexion aux instances

```bash
# Jenkins Controller
ssh -i ~/.ssh/skool-key.pem ec2-user@<JENKINS_IP>

# Serveur de déploiement
ssh -i ~/.ssh/skool-key.pem ec2-user@<DEPLOYMENT_IP>
```

## Nettoyage

Pour détruire toute l'infrastructure :
```bash
cd terraform
terraform destroy -auto-approve
```

## Dépannage

### Erreur de connexion SSH
- Vérifiez les permissions de la clé : `chmod 400 ~/.ssh/skool-key.pem`
- Ajoutez les clés hôtes : `ssh-keyscan -H <IP> >> ~/.ssh/known_hosts`

### Jenkins ne démarre pas
- Vérifiez les logs : `sudo journalctl -u jenkins -f`
- Redémarrez le service : `sudo systemctl restart jenkins`

### Pipeline échoue
- Vérifiez les credentials Docker Hub
- Assurez-vous que le repo Git est accessible
- Vérifiez les logs du build Jenkins

### Problème de disque
Si vous voyez des avertissements de disque, l'instance a été configurée avec 50GB.

## Personnalisation

### Changer la région AWS
Modifiez `terraform/main.tf` :
```hcl
provider "aws" {
  region = "eu-west-1"  # ou autre région
}
```

### Changer le type d'instance
Modifiez la variable `instance_type` dans `terraform/main.tf` :
```hcl
variable "instance_type" {
  default = "t3.small"  # ou autre type
}
```

### Ajouter des plugins Jenkins
Modifiez `ansible/deploy_jenkins.yml` pour installer des plugins supplémentaires.

## Support

Si vous rencontrez des problèmes :
1. Vérifiez les logs Ansible/Terraform
2. Consultez les issues GitHub
3. Vérifiez votre configuration AWS

## Licence

Ce projet est sous licence MIT.

## test
