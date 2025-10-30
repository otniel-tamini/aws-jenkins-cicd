pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('DOCKERHUB_CREDENTIALS')
        IMAGE_NAME = "otniel217/flask-ci-cd-demo"
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'master', url: 'https://github.com/otniel-tamini/aws-jenkins-cicd.git'
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
                    try {
                        sh """
                            ssh -o StrictHostKeyChecking=no -i ~/.ssh/skool-key.pem ec2-user@54.91.166.242 '
                                docker pull ${IMAGE_NAME}:${env.BUILD_NUMBER}
                                docker stop flask-app || true
                                docker rm flask-app || true
                                docker run -d --name flask-app -p 5000:8000 ${IMAGE_NAME}:${env.BUILD_NUMBER}
                            '
                        """
                    } catch (err) {
                        // Rollback: restart the container with the previous 'latest' image
                        sh """
                            ssh -o StrictHostKeyChecking=no -i ~/.ssh/skool-key.pem ec2-user@54.91.166.242 '
                                docker pull ${IMAGE_NAME}:latest
                                docker stop flask-app || true
                                docker rm flask-app || true
                                docker run -d --name flask-app -p 5000:8000 ${IMAGE_NAME}:latest
                            '
                        """
                        error("Deployment failed, rollback performed with the 'latest' image.")
                    }
                }
            }
        }
    }

    post {
        success {
            slackSend(
                channel: '#aws-jenkins-cicd',
                color: 'good',
                message: """
                    ✅ *Deployment succeeded* - ${env.JOB_NAME}
                    *Branch:* ${GIT_BRANCH}
                    *Build:* #${env.BUILD_NUMBER}
                    *Duration:* ${currentBuild.durationString.replace(' and counting', '')}
                    *Link:* ${env.BUILD_URL}
                """.stripIndent()
            )
        }
        failure {
            slackSend(
                channel: '#aws-jenkins-cicd',
                color: 'danger',
                message: """
                    ❌ *Deployment failed* - ${env.JOB_NAME}
                    *Branch:* ${GIT_BRANCH}
                    *Build:* #${env.BUILD_NUMBER}
                    *Duration:* ${currentBuild.durationString.replace(' and counting', '')}
                    *Link:* ${env.BUILD_URL}
                """.stripIndent()
            )
        }
        unstable {
            slackSend(
                channel: '#aws-jenkins-cicd',
                color: 'warning',
                message: """
                    ⚠️ *Unstable build* - ${env.JOB_NAME}
                    *Branch:* ${GIT_BRANCH}
                    *Build:* #${env.BUILD_NUMBER}
                    *Link:* ${env.BUILD_URL}
                """.stripIndent()
            )
        }
    }

}