pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build & Push Image') {
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
                mkdir -p ~/laravel-ecommerce-cicd
                cp -r * ~/laravel-ecommerce-cicd/ || true

                # FIX PERMISSIONS INSIDE CONTAINER (NO SUDO!)
                docker exec -u root cicd-app-1 chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache 2>/dev/null || true
                docker exec -u root cicd-app-1 chmod -R 775 /var/www/storage /var/www/bootstrap/cache 2>/dev/null || true

                cd ~/laravel-ecommerce-cicd
                docker-compose -f docker-compose-jenkins.yml -p cicd down || true
                docker-compose -f docker-compose-jenkins.yml -p cicd up -d --remove-orphans

                sleep 15

                # Run Laravel setup
                docker exec cicd-app-1 composer install --no-dev --optimize-autoloader
                docker exec cicd-app-1 php artisan key:generate --force
                docker exec cicd-app-1 php artisan migrate --force --seed
                docker exec cicd-app-1 php artisan config:cache
                docker exec cicd-app-1 php artisan route:cache
                docker exec cicd-app-1 php artisan view:cache
                '''
            }
        }
    }

    post {
        success { echo 'LIVE: http://3.106.170.54:8081' }
        failure { echo 'FAILED!' }
    }
}
