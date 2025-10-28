pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-login')
        IMAGE_NAME = "your_dockerhub_username/flask-ci-cd-demo"
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/your-username/your-repo.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    dockerImage = docker.build("${IMAGE_NAME}:${env.BUILD_NUMBER}")
                }
            }
        }

        stage('Run Unit Tests') {
            steps {
                script {
                    dockerImage.inside {
                        sh 'python -m pytest tests/ -v'
                    }
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                script {
                    docker.withRegistry('https://registry.hub.docker.com', 'DOCKERHUB_CREDENTIALS') {
                        dockerImage.push("${env.BUILD_NUMBER}")
                        dockerImage.push("latest")
                    }
                }
            }
        }

        stage('Deploy to EC2') {
            steps {
                script {
                    sh """
                        ssh -o StrictHostKeyChecking=no -i ~/.ssh/skool-key.pem ec2-user@54.146.221.14 '
                            docker pull ${IMAGE_NAME}:${env.BUILD_NUMBER}
                            docker stop flask-app || true
                            docker rm flask-app || true
                            docker run -d --name flask-app -p 5000:5000 ${IMAGE_NAME}:${env.BUILD_NUMBER}
                        '
                    """
                }
            }
        }
    }

    post {
        always {
            script {
                try {
                    sh 'docker rmi ${IMAGE_NAME}:${BUILD_NUMBER}'
                } catch (Exception e) {
                    echo 'Failed to remove Docker image'
                }
            }
        }
    }
}