pipeline {
    agent any
    environment {
        IMAGE = 'sabeen123/laravel-ecommerce'
    }
    stages {
        stage('Clone') {
            steps {
                git branch: 'main', url: 'https://github.com/sabeen864/laravel-ecommerce-cicd.git'
            }
        }
        stage('Build & Push') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                    sh "docker build -t ${IMAGE}:${BUILD_NUMBER} ."
                    sh "docker tag ${IMAGE}:${BUILD_NUMBER} ${IMAGE}:latest"
                    sh "echo \$PASS | docker login -u \$USER --password-stdin"
                    sh "docker push ${IMAGE}:${BUILD_NUMBER}"
                    sh "docker push ${IMAGE}:latest"
                }
            }
        }
        stage('Deploy') {
            steps {
                sh 'docker-compose -f docker-compose-jenkins.yml down || true'
                sh 'docker-compose -f docker-compose-jenkins.yml up -d'
            }
        }
    }
    post { 
        always { 
            sh 'docker system prune -f' 
        } 
    }
}