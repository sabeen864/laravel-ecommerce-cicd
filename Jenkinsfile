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
                cd ${WORKSPACE}
                # COPY CODE TO SHARED VOLUME
                mkdir -p /var/lib/jenkins/app-data
                rm -rf /var/lib/jenkins/app-data/*
                cp -r . /var/lib/jenkins/app-data/
                # UPDATE .env
                cp .env.example /var/lib/jenkins/app-data/.env
                sed -i "s|APP_URL=.*|APP_URL=http://3.106.170.54:8081|g" /var/lib/jenkins/app-data/.env
                docker-compose -f docker-compose-jenkins.yml -p cicd down || true
                docker-compose -f docker-compose-jenkins.yml -p cicd up -d --remove-orphans
                sleep 40
                # COPY .env INTO CONTAINER (app container still needs it)
                docker cp /var/lib/jenkins/app-data/.env cicd-app-1:/var/www/.env
                docker exec -u root cicd-app-1 mkdir -p /var/www/storage/logs /var/www/storage/framework/views
                docker exec -u root cicd-app-1 chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache /var/www/.env
                docker exec -u root cicd-app-1 chmod -R 775 /var/www/storage /var/www/bootstrap/cache
                docker exec -u root cicd-app-1 chmod 644 /var/www/.env
                docker exec cicd-app-1 composer install --no-dev --optimize-autoloader
                docker exec cicd-app-1 php artisan key:generate --force
                docker exec cicd-app-1 php artisan migrate --force
                docker exec cicd-app-1 php artisan config:cache
                '''
            }
        }
    }
    post {
        success { echo 'LIVE: http://3.106.170.54:8081' }
        failure { echo 'FAILED!' }
    }
}
