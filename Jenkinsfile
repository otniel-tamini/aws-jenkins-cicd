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
                    sh """
                        ssh -o StrictHostKeyChecking=no -i ~/.ssh/skool-key.pem ec2-user@54.91.166.242 '
                            docker pull ${IMAGE_NAME}:${env.BUILD_NUMBER}
                            docker stop flask-app || true
                            docker rm flask-app || true
                            docker run -d --name flask-app -p 5000:8000 ${IMAGE_NAME}:${env.BUILD_NUMBER}
                        '
                    """
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
                    ✅ *Déploiement réussi* - ${env.JOB_NAME}
                    *Branche:* ${GIT_BRANCH}
                    *Build:* #${env.BUILD_NUMBER}
                    *Durée:* ${currentBuild.durationString.replace(' and counting', '')}
                    *Lien:* ${env.BUILD_URL}
                """.stripIndent()
            )
        }
        failure {
            slackSend(
                channel: '#aws-jenkins-cicd',
                color: 'danger',
                message: """
                    ❌ *Déploiement échoué* - ${env.JOB_NAME}
                    *Branche:* ${GIT_BRANCH}
                    *Build:* #${env.BUILD_NUMBER}
                    *Durée:* ${currentBuild.durationString.replace(' and counting', '')}
                    *Lien:* ${env.BUILD_URL}
                """.stripIndent()
            )
        }
        unstable {
            slackSend(
                channel: '#aws-jenkins-cicd',
                color: 'warning',
                message: """
                    ⚠️ *Build instable* - ${env.JOB_NAME}
                    *Branche:* ${GIT_BRANCH}
                    *Build:* #${env.BUILD_NUMBER}
                    *Lien:* ${env.BUILD_URL}
                """.stripIndent()
            )
        }
    }

}