pipeline {
    agent any
    stages {
        stage('Checkout') {
            steps { checkout scm }
        }
        stage('Deploy') {
            steps {
                sh '''
                cd ${WORKSPACE}
                # Get current public IP dynamically (with timeout)
                PUBLIC_IP=$(timeout 5 curl -s http://169.254.169.254/latest/meta-data/public-ipv4 || echo "13.54.247.55")
                echo "Deploying to: http://${PUBLIC_IP}:8081"
                
                # Pull latest image
                docker pull sabeen123/laravel-ecommerce:latest
                
                # Stop existing containers
                docker-compose -f docker-compose-jenkins.yml -p cicd down || true
                
                # Update .env file
                cp .env.example .env
                sed -i "s|APP_URL=.*|APP_URL=http://${PUBLIC_IP}:8081|g" .env
                sed -i "s|DB_HOST=.*|DB_HOST=db|g" .env
                sed -i "s|DB_DATABASE=.*|DB_DATABASE=clothing|g" .env
                sed -i "s|DB_USERNAME=.*|DB_USERNAME=laravel|g" .env
                sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=secret|g" .env
                sed -i "s|APP_KEY=.*|APP_KEY=base64:$(openssl rand -base64 32)|g" .env
                
                # Start containers
                docker-compose -f docker-compose-jenkins.yml -p cicd up -d --remove-orphans
                
                # Wait for containers
                sleep 20
                
                # Copy .env into container
                docker cp .env cicd-app-1:/var/www/.env
                
                # Set permissions
                docker exec -u root cicd-app-1 chown www-data:www-data /var/www/.env
                docker exec -u root cicd-app-1 chmod 644 /var/www/.env
                
                # Run Laravel setup
                docker exec cicd-app-1 php artisan migrate --force
                docker exec cicd-app-1 php artisan storage:link
                docker exec cicd-app-1 php artisan config:cache
                
                echo "✅ LIVE: http://${PUBLIC_IP}:8081"
                '''
            }
        }
        stage('Test') {
            agent {
                docker {
                    image 'markhobson/maven-chrome:latest'
                    args '--network host -v /var/run/docker.sock:/var/run/docker.sock'
                    reuseNode true
                }
            }
            steps {
                script {
                    echo 'Starting Selenium UI Tests...'
                    // Clone the test repository
                    sh '''
                        # Clean up any previous test directory
                        rm -rf laravel-ecommerce-tests
                        
                        # Clone the tests repository
                        git clone https://github.com/sabeen864/laravel-ecommerce-tests.git
                        cd laravel-ecommerce-tests
                        echo "Test repository cloned successfully"
                        ls -la
                        
                        echo "Running Maven tests..."
                        # FIX: Using local repo to avoid Permission Denied error
                        mvn -Dmaven.repo.local=./.m2/repository clean test
                    '''
                }
            }
            post {
                always {
                    // Publish JUnit test results
                    junit allowEmptyResults: true, testResults: '**/target/surefire-reports/*.xml'
                    // Archive test reports
                    archiveArtifacts artifacts: '**/target/surefire-reports/*', allowEmptyArchive: true
                }
                success {
                    echo '✅ All Selenium tests passed!'
                }
                failure {
                    echo '❌ Some Selenium tests failed!'
                }
            }
        }
    }
    post {
        always {
            script {
                // Get the pusher's email from Git SCM
                def pusherEmail = sh(
                    script: "git log -1 --pretty=format:'%ae'",
                    returnStdout: true
                ).trim()
                
                // Fallback email if pusher email is not found
                if (!pusherEmail || pusherEmail.isEmpty()) {
                    pusherEmail = 'sabeen864@gmail.com'
                }
                
                echo "📧 Sending notification to: ${pusherEmail}"
                
                // Determine build status
                def buildStatus = currentBuild.result ?: 'SUCCESS'
                def statusIcon = buildStatus == 'SUCCESS' ? '✅' : '❌'
                def statusColor = buildStatus == 'SUCCESS' ? 'green' : 'red'
                
                // Send email notification
                emailext(
                    to: pusherEmail,
                    subject: "${statusIcon} Laravel Ecommerce CI/CD - Build #${BUILD_NUMBER} - ${buildStatus}",
                    body: """
                        <html>
                        <body style="font-family: Arial, sans-serif;">
                            <h2 style="color: ${statusColor};">${statusIcon} Build ${buildStatus}</h2>
                            <h3>Build Information</h3>
                            <ul>
                                <li><strong>Project:</strong> ${JOB_NAME}</li>
                                <li><strong>Build Number:</strong> ${BUILD_NUMBER}</li>
                                <li><strong>Status:</strong> <span style="color: ${statusColor}; font-weight: bold;">${buildStatus}</span></li>
                                <li><strong>Duration:</strong> ${currentBuild.durationString}</li>
                            </ul>
                            <h3>Stage Results</h3>
                            <ul>
                                <li>✅ Checkout: Completed</li>
                                <li>✅ Deploy: ${buildStatus == 'SUCCESS' ? 'Completed' : 'Check logs'}</li>
                                <li>${buildStatus == 'SUCCESS' ? '✅' : '❌'} Test: ${buildStatus == 'SUCCESS' ? 'All tests passed' : 'Some tests failed'}</li>
                            </ul>
                            <h3>Application URLs</h3>
                            <ul>
                                <li><strong>Live App:</strong> <a href="http://13.27.51.77:8081">http://13.27.51.77:8081</a></li>
                                <li><strong>Jenkins:</strong> <a href="${BUILD_URL}">${BUILD_URL}</a></li>
                                <li><strong>Test Results:</strong> <a href="${BUILD_URL}testReport/">${BUILD_URL}testReport/</a></li>
                            </ul>
                            <p style="margin-top: 20px; color: #666;">
                                <em>This is an automated notification from Jenkins CI/CD Pipeline</em>
                            </p>
                        </body>
                        </html>
                    """,
                    mimeType: 'text/html',
                    attachLog: true
                )
            }
        }
        success {
            echo '✅ PIPELINE COMPLETED SUCCESSFULLY!'
        }
        failure {
            echo '❌ PIPELINE FAILED!'
        }
    }
}
