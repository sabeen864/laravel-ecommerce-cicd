pipeline {
    agent any
    stages {
        stage('Checkout') { steps { checkout scm } }
        stage('Build & Push') {
            steps {
                sh '''
                docker build -t sabeen123/laravel-ecommerce:latest .
                docker push sabeen123/laravel-ecommerce:latest
                '''
            }
        }
        stage('Deploy') {
            steps {
                sh '''
                docker-compose -f docker-compose-jenkins.yml -p cicd down || true
                docker-compose -f docker-compose-jenkins.yml -p cicd up -d
                sleep 40
                docker exec cicd-app-1 php artisan key:generate --force
                docker exec cicd-app-1 php artisan migrate --force
                docker exec cicd-app-1 php artisan config:cache
                '''
            }
        }
    }
    post {
        success { echo 'LIVE: http://3.106.170.54:8081' }
    }
}
