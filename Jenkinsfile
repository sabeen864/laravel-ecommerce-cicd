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
                // Stop the old container set, using a distinct project name
                sh 'docker-compose -f docker-compose-jenkins.yml -p cicd down || true'
                
                // Start the new container set using a distinct project name
                // The -d flag ensures the containers run in the background after the pipeline finishes.
                sh 'docker-compose -f docker-compose-jenkins.yml -p cicd up -d'
                
                // Wait for a reasonable time for all services (DB/App/Nginx) to initialize
                sh 'echo "Waiting 20 seconds for application to start..."'
                sh 'sleep 20' 
                
                // Final check: Use curl to verify the website is reachable on 8081.
                // The -f (fail) flag ensures the pipeline fails if the connection is reset or fails, 
                // but if successful, it confirms the site is up.
                sh 'curl -f http://localhost:8081 || (echo "Deployment failed: Application not reachable on 8081" && exit 1)'
            }
        }
    }
    post {
        always {
            sh 'docker system prune -f'
        }
    }
}
