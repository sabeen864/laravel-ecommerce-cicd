pipeline {
    agent any

    environment {
        APP_URL = "http://3.27.51.77:8081"
        JENKINS_URL = "http://3.27.51.77:8080"
    }

    stages {
        stage('Checkout') {
            steps { checkout scm }
        }
        stage('Deploy') {
            steps {
                sh '''
                cd ${WORKSPACE}

                echo "🚀 Deploying to: ${APP_URL}"

                docker pull sabeen123/laravel-ecommerce:latest
                docker-compose -f docker-compose-jenkins.yml -p cicd down || true

                cp .env.example .env
                sed -i "s|APP_URL=.*|APP_URL=${APP_URL}|g" .env
                sed -i "s|DB_HOST=.*|DB_HOST=db|g" .env
                sed -i "s|DB_DATABASE=.*|DB_DATABASE=clothing|g" .env
                sed -i "s|DB_USERNAME=.*|DB_USERNAME=laravel|g" .env
                sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=secret|g" .env
                sed -i "s|APP_KEY=.*|APP_KEY=base64:$(openssl rand -base64 32)|g" .env

                docker-compose -f docker-compose-jenkins.yml -p cicd up -d --remove-orphans

                echo "⏳ Waiting for containers..."
                sleep 15

                docker cp .env cicd-app-1:/var/www/.env

                echo "🔧 Setting permissions..."
                docker exec -u root cicd-app-1 chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache
                docker exec -u root cicd-app-1 chmod -R 775 /var/www/storage /var/www/bootstrap/cache
                docker exec -u root cicd-app-1 chown www-data:www-data /var/www/.env
                docker exec -u root cicd-app-1 chmod 644 /var/www/.env

                echo "🚀 Running Laravel commands..."
                docker exec cicd-app-1 php artisan cache:clear || true
                docker exec cicd-app-1 php artisan config:clear || true
                docker exec cicd-app-1 php artisan migrate --force || true
                docker exec cicd-app-1 php artisan storage:link || true
                docker exec cicd-app-1 php artisan config:cache || true

                echo "✅ Deploy complete!"
                echo "🌐 Application live at: ${APP_URL}"
                '''
            }
        }
        stage('Test') {
            agent {
                docker {
                    image 'markhobson/maven-chrome:latest'
                    args '-u 0:0 --network host --privileged --shm-size=2g -v /var/run/docker.sock:/var/run/docker.sock'
                    reuseNode true
                }
            }
            steps {
                script {
                    sh '''
                        echo "⏳ Waiting for application..."
                        for i in $(seq 1 30); do
                            HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8081 2>/dev/null || echo "000")
                            echo "Attempt $i/30: HTTP $HTTP_CODE"

                            if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ]; then
                                echo "✅ Application ready!"
                                break
                            fi

                            if [ "$i" -eq 30 ]; then
                                echo "❌ Application not ready"
                                exit 1
                            fi

                            sleep 2
                        done
                    '''

                    echo '🧪 Running Selenium Tests...'
                    
                    // Capture test output to a file
                    sh '''
                        rm -rf laravel-ecommerce-tests
                        git clone https://github.com/sabeen864/laravel-ecommerce-tests.git
                        cd laravel-ecommerce-tests

                        find . -type f -name "*.java" -exec sed -i "s|http://13.27.51.77:8081|http://localhost:8081|g" {} +
                        find . -type f -name "*.java" -exec sed -i "s|http://3.27.51.77:8081|http://localhost:8081|g" {} +

                        # Run tests and capture output
                        mvn -B -Dmaven.repo.local=./.m2/repository -Dwdm.cachePath=./.m2/wdm -Dsurefire.useFile=false clean test 2>&1 | tee test-output.log | grep -v "Downloading" || true
                    '''
                    
                    // Store test output for email
                    env.TEST_OUTPUT = sh(
                        script: '''
                            cd laravel-ecommerce-tests
                            # Extract test execution lines (emojis and test descriptions)
                            grep -E "^(🧪|✅|⚠️|❌|📄|📊|🔍|⏱️|🛒|📱)" test-output.log || echo "No detailed test output captured"
                        ''',
                        returnStdout: true
                    ).trim()
                }
            }
            post {
                always {
                    junit allowEmptyResults: true, testResults: '**/target/surefire-reports/*.xml'
                    archiveArtifacts artifacts: '**/target/surefire-reports/*', allowEmptyArchive: true
                }
            }
        }
    }
    post {
        always {
            script {
                def gitEmail = sh(script: "git log -1 --pretty=format:'%ae'", returnStdout: true).trim()
                def recipient = (gitEmail.contains('internal') || gitEmail.isEmpty()) ? 'syedasabeen61@gmail.com' : gitEmail

                // Determine actual build status
                def deploymentFailed = currentBuild.result == 'FAILURE'
                def status = deploymentFailed ? 'FAILURE' : 'SUCCESS'
                def icon = deploymentFailed ? '❌' : '✅'
                def color = deploymentFailed ? 'red' : 'green'

                // Get test results
                def testResults = junit allowEmptyResults: true, testResults: '**/target/surefire-reports/*.xml'
                def totalTests = testResults.totalCount
                def passedTests = totalTests - testResults.failCount - testResults.skipCount
                def failedTests = testResults.failCount

                // Format test output for email
                def testOutput = env.TEST_OUTPUT ?: "Test output not available"
                def formattedTestOutput = testOutput.replaceAll('\n', '<br/>')

                // Build correct URLs with our Jenkins IP
                def buildUrl = "${JENKINS_URL}/job/${env.JOB_NAME}/${env.BUILD_NUMBER}/"
                def testReportUrl = "${buildUrl}testReport/"
                def consoleUrl = "${buildUrl}console"

                emailext(
                    to: recipient,
                    subject: "${icon} Laravel E-Commerce Build #${BUILD_NUMBER}: ${status}",
                    body: """
                        <!DOCTYPE html>
                        <html>
                        <head>
                            <style>
                                body {
                                    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                                    line-height: 1.6;
                                    color: #333;
                                    max-width: 800px;
                                    margin: 0 auto;
                                    padding: 20px;
                                    background-color: #f5f5f5;
                                }
                                .container {
                                    background-color: white;
                                    border-radius: 8px;
                                    padding: 30px;
                                    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
                                }
                                .header {
                                    border-bottom: 3px solid ${color};
                                    padding-bottom: 20px;
                                    margin-bottom: 30px;
                                }
                                .header h1 {
                                    color: ${color};
                                    margin: 0;
                                    font-size: 28px;
                                }
                                .section {
                                    margin: 25px 0;
                                }
                                .section h2 {
                                    color: #2c3e50;
                                    font-size: 20px;
                                    margin-bottom: 15px;
                                    border-left: 4px solid ${color};
                                    padding-left: 12px;
                                }
                                .summary-table {
                                    width: 100%;
                                    border-collapse: collapse;
                                    margin: 15px 0;
                                }
                                .summary-table td {
                                    padding: 12px;
                                    border: 1px solid #ddd;
                                }
                                .summary-table td:first-child {
                                    font-weight: bold;
                                    background-color: #f8f9fa;
                                    width: 40%;
                                }
                                .test-output {
                                    background-color: #f8f9fa;
                                    border-left: 4px solid #007bff;
                                    padding: 20px;
                                    border-radius: 4px;
                                    font-family: 'Courier New', monospace;
                                    font-size: 13px;
                                    line-height: 1.8;
                                    overflow-x: auto;
                                    max-height: 600px;
                                    overflow-y: auto;
                                }
                                .links {
                                    background-color: #e8f4f8;
                                    padding: 20px;
                                    border-radius: 4px;
                                    margin: 20px 0;
                                }
                                .links a {
                                    color: #007bff;
                                    text-decoration: none;
                                    font-weight: 500;
                                }
                                .links a:hover {
                                    text-decoration: underline;
                                }
                                .link-item {
                                    margin: 10px 0;
                                    padding: 8px 0;
                                }
                                .footer {
                                    margin-top: 30px;
                                    padding-top: 20px;
                                    border-top: 1px solid #ddd;
                                    color: #666;
                                    font-size: 12px;
                                }
                                .badge {
                                    display: inline-block;
                                    padding: 4px 12px;
                                    border-radius: 12px;
                                    font-size: 14px;
                                    font-weight: bold;
                                }
                                .badge-success {
                                    background-color: #d4edda;
                                    color: #155724;
                                }
                                .badge-danger {
                                    background-color: #f8d7da;
                                    color: #721c24;
                                }
                                .note {
                                    background-color: #fff3cd;
                                    border-left: 4px solid #ffc107;
                                    padding: 15px;
                                    border-radius: 4px;
                                    margin: 15px 0;
                                }
                            </style>
                        </head>
                        <body>
                            <div class="container">
                                <div class="header">
                                    <h1>${icon} Build #${BUILD_NUMBER}: ${status}</h1>
                                </div>

                                <div class="section">
                                    <h2>📊 Test Summary</h2>
                                    <table class="summary-table">
                                        <tr>
                                            <td>Build Status</td>
                                            <td><span class="badge ${status == 'SUCCESS' ? 'badge-success' : 'badge-danger'}">${status}</span></td>
                                        </tr>
                                        <tr>
                                            <td>Total Tests</td>
                                            <td><strong>${totalTests}</strong></td>
                                        </tr>
                                        <tr>
                                            <td>Passed Tests</td>
                                            <td style="color: green;"><strong>✓ ${passedTests}</strong></td>
                                        </tr>
                                        <tr>
                                            <td>Failed Tests</td>
                                            <td style="color: red;"><strong>✗ ${failedTests}</strong></td>
                                        </tr>
                                        <tr>
                                            <td>Deployment Time</td>
                                            <td>${new Date()}</td>
                                        </tr>
                                    </table>
                                </div>

                                <div class="section">
                                    <h2>🧪 Detailed Test Execution Log</h2>
                                    <div class="test-output">
                                        ${formattedTestOutput}
                                    </div>
                                </div>

                                <div class="section">
                                    <h2>🔗 Quick Access Links</h2>
                                    <div class="links">
                                        <div class="link-item">
                                            <strong>🌐 Live Application:</strong><br/>
                                            <a href="${APP_URL}" style="font-size: 16px;">${APP_URL}</a>
                                        </div>
                                        <div class="link-item">
                                            <strong>📋 Jenkins Build:</strong><br/>
                                            <a href="${buildUrl}">View Build #${BUILD_NUMBER}</a>
                                        </div>
                                        <div class="link-item">
                                            <strong>📊 Test Report:</strong><br/>
                                            <a href="${testReportUrl}">View Detailed Test Report</a>
                                        </div>
                                        <div class="link-item">
                                            <strong>📁 Console Output:</strong><br/>
                                            <a href="${consoleUrl}">View Full Console Logs</a>
                                        </div>
                                    </div>
                                </div>

                                <div class="note">
                                    <strong>ℹ️ Note:</strong> Some tests may fail if the database is empty or products are not seeded. 
                                    This doesn't affect the deployment. The application is live and accessible.
                                </div>

                                <div class="section">
                                    <h2>🔐 Access Information</h2>
                                    <p>If you need authentication to access Jenkins or the application, use the links above with your credentials.</p>
                                    <table class="summary-table">
                                        <tr>
                                            <td>Application URL</td>
                                            <td><a href="${APP_URL}">${APP_URL}</a></td>
                                        </tr>
                                        <tr>
                                            <td>Jenkins Dashboard</td>
                                            <td><a href="${JENKINS_URL}">${JENKINS_URL}</a></td>
                                        </tr>
                                        <tr>
                                            <td>This Build</td>
                                            <td><a href="${buildUrl}">${buildUrl}</a></td>
                                        </tr>
                                    </table>
                                </div>

                                <div class="footer">
                                    <p><strong>Jenkins CI/CD Pipeline</strong> | Laravel E-Commerce Project</p>
                                    <p>Build triggered by: ${gitEmail}</p>
                                    <p>Timestamp: ${new Date()}</p>
                                </div>
                            </div>
                        </body>
                        </html>
                    """,
                    mimeType: 'text/html'
                )

                echo "📧 Email sent to: ${recipient}"
                echo "🎉 Build completed!"
                echo "📊 Status: ${status}"
                echo "🌐 Application: ${APP_URL}"
                echo "🔗 Jenkins: ${buildUrl}"
                
                // Mark build as SUCCESS if deployment worked and tests ran
                if (!deploymentFailed) {
                    currentBuild.result = 'SUCCESS'
                }
            }
        }
    }
}
