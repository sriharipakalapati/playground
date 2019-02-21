#!groovy
@Library("Jenkins_Library@1.0.0") _


pipeline {
    agent {
		node {
			label 'master'
			customWorkspace "D://Jenkins//${env.JOB_NAME}".replace('%2F', '_')
		}
	}

	parameters{
		string(	defaultValue: "19.3.0", 
				description: 'The Major.Minor.Patch for the Component level. This will update the CDA ComponentVersion.', 
				name: 'COMPONENTVERSION' )

		string(	defaultValue: "19", 
				description: 'The Major.Minor.Patch for the Component level. This will update the CDA assemlyinfo.', 
				name: 'MAJOR_VERSION' )

		string(	defaultValue: "3", 
				description: 'The Major.Minor.Patch for the Component level. This will update the assemlyinfo.', 
				name: 'MINOR_VERSION' )

		string(	defaultValue: 'https://bams-aws.refinitiv.com/artifactory/api/nuget/default.nuget.cloud/nawm/WM-Envision/envision-web/', 
				description: 'Used for Solution file name and the build file name. Make sure they match!', 
				name: 'BAMSURI' )

		string( defaultValue: '24814',
				description: 'The SAMI GIT PROJECT ID',
				name: 'GIT_PROJECT_ID' ) 

	    string(	defaultValue: 'envision_web-hieradata', 
				description: 'Main Hieradata project should be in the nawm_deploy group', 
				name: 'HIERADATA_PROJECT' )

	    string(	defaultValue: 'envision_web-r10k', 
				description: 'R10K project should be in the nawm_deploy group', 
				name: 'R10K_PROJECT' )			

	    string(	defaultValue: 'Wealth_Management', 
				description: 'Main Hieradata project should be in the nawm_deploy group', 
				name: 'CDA_PLATFORM' )

	    string(	defaultValue: 'WM_Envision', 
				description: 'Main Hieradata project should be in the nawm_deploy group', 
				name: 'COMPONENT_GROUP' )

		string( defaultValue: 'envision_web',
				description: 'Component on CDA',
				name: 'COMPONENT' )
     
		string( defaultValue: "WM-Devops@thomsonreuters.com,TF.Envision@tr.com",
				description: 'E-mail Addresses for users who need failed or succesful build e-mails',
				name: 'EMAIL_LIST')

		booleanParam( defaultValue: false,
		        description: 'True false testing mechanism',
				name: 'FULL_BUILD')	
		
		booleanParam( defaultValue: false,
		        description: 'True false testing mechanism',
				name: 'CRON_FULL_BUILD')		
		
		string( defaultValue: 'development',
		        description: 'Quality Grade for build',
				name: 'QualityGate')			
	}

	environment {
		GIT_CREDS = credentials('s.tr.wmbot - Gitlab')
        GIT_API_TOKEN = 'BS9xhzd_tJXuzRExBxn-'		
		COMPASS_API_KEY = credentials('s.tr.wmbot_COMPASS_APIKEY')
		ComponentVersion = "${params.COMPONENTVERSION}.${env.BUILD_NUMBER}"
		SnapshotComponentVersion = "${params.COMPONENTVERSION}.${env.BUILD_NUMBER}-snapshot"		
		//use git describe --abbrev=0 to grab the latest tag and update the number from there
		//For Release and Hotfix branches - the commit prior to the Merge Request is what needs to be tagged 
		//This is because release and hotfix branches should "tag then merge" to properly prevent issuess
		BAMS_CREDS = credentials('s.tr.wmbot_BAMS_AWS_APIKEY')
		SLACK_CREDS = credentials('Slack_API_Token')
		PROJECT_NAME = 	"WM_WachoviaCode"
		RELEASE_VERSION_NAME = "envision_web::params::envision_release_version:"
		HIERA_VERSION_NAME = "envision_web::params::envision_web_version:"	
		RUNDECK_UUID = "b4d8c70c-2933-49c8-81ba-4b8f19dc7153"					
	}

    options {
	    skipDefaultCheckout() 
        gitLabConnection('GitLab_Generic')	
		timeout(time: 60, unit: 'MINUTES')
    }

	
   triggers {    
       //cron(cron_string)
       parameterizedCron(BRANCH_NAME == "release/WFA19.3.0" ? "H 20 * * 1-5 % CRON_FULL_BUILD=true; QualityGate=development" :"")  
       //parameterizedCron(BRANCH_NAME == "release/WFA19.3.0" ? "" :"")  
    }

    stages {
		stage('Checkout Branch') {
			steps{
					checkout scm
			}			
		}

		stage('Pre-Build') {
			steps {	
				parallel (
					R10K_Git: { dir("${env.WORKSPACE}\\${params.R10K_PROJECT}") {
						git ([url: "git@git.sami.int.thomsonreuters.com:nawm_deploy/${params.R10K_PROJECT}.git", credentialsId:"SSH_USER_WITH_KEY"])
					} },

					Hieradata_Git: { dir("${env.WORKSPACE}\\${params.HIERADATA_PROJECT}") {
						git ([url: "git@git.sami.int.thomsonreuters.com:nawm_deploy/${params.HIERADATA_PROJECT}.git", credentialsId:"SSH_USER_WITH_KEY"])
					} },

					Jenkins_Scripts_Git: { dir("${env.WORKSPACE}\\build\\scripts") {
						git ([url: "git@git.sami.int.thomsonreuters.com:nawm_tools/Jenkins_Scripts.git", credentialsId:"SSH_USER_WITH_KEY"])
					} }
				)
			}
		}

		stage('Build') {
			steps {
				dir("${env.WORKSPACE}\\Products\\Wachovia") {
					bat 'nuget.exe restore TF.WM.BPI.Wachovia.sln'
				}

				dir("${env.WORKSPACE}\\Products\\Wachovia\\build") {
					bat "\"${tool 'msbuild'}\"  %PROJECT_NAME%.XML  /p:SolutionFolder=\"${env.WORKSPACE}\\Products\\Wachovia\",CURRENT_ENVISION_BUILD_VERSION=${env.ComponentVersion},MAJOR_VER=${env.MAJOR_VERSION},MINOR_VER=${env.MINOR_VERSION},BUILD_NUMBER=${env.BUILD_NUMBER}"
				}

				dir("${env.WORKSPACE}") {
					echo "Creating a Build status file"
                    writeFile file: "output/MR_Title.txt", text: "BUILD STATUS:"
				}
			}
		}

		stage('Set FULL_BUILD' ){
			when {
				anyOf { branch 'develop'; branch 'release/*' }
			}
			steps{
				dir("${env.WORKSPACE}") {
                script {
                        def IsFullBuild = params.FULL_BUILD
                        def IsManulBuild = false
                        IsManulBuild = isManualBuild() 
                        echo "is manual Build: $IsManulBuild"
                        echo "FULL_BUILD Parameter Value: ${params.FULL_BUILD}"
						echo "IsFullBuild Value before: $IsFullBuild"
					//	def startedByTimer = false
					//	startedByTimer = isJobStartedByTimer()
					//	echo "is job started by timer: $startedByTimer"
						echo "is CRON_FULL_BUILD: ${params.CRON_FULL_BUILD}"
						echo "QualityGate: ${params.QualityGate}"
					//	if (startedByTimer & params.CRON_FULL_BUILD )
						if (params.CRON_FULL_BUILD )
						{
							IsFullBuild = true
							IsManulBuild = true
						    echo "IsFullBuild Value after: $IsFullBuild"	
                        }	

                        def command = "./build/scripts/WFAMergeRequestAPI.ps1" 
                        def comamdParameter = "-GIT_CREDENTIALS ${env.GIT_API_TOKEN} -PROJECT_ID ${env.GIT_PROJECT_ID} -BranchName ${env.BRANCH_NAME} -IsManualFullBuildAsStr $IsFullBuild  -IsManulBuildAsStr $IsManulBuild | Out-File output/MR_Title.txt -Encoding utf8"
                        echo "command is $command"
                        //echo "comamd Parameter is : $comamdParameter"
                        def psCommand = "powershell.exe -ExecutionPolicy Bypass -NoProfile  -Command \"& \'$command\' $comamdParameter\""
                        echo "psCommand is: $psCommand"
                        bat psCommand
                        def fileContext = readFile('output/MR_Title.txt').contains("FULL BUILD")
                        echo "File Contains FULL_BUILD: $fileContext"

						def CurrentComponentVersion = getComponentVersion()
						echo "Current Component Version is: $CurrentComponentVersion" 
                   }
				}
			}
		}

		stage('Package Snapshot') {
			when {			
					anyOf { branch 'develop'; branch 'release/*' }
					not {
						expression {
								readFile("${env.WORKSPACE}/output/MR_Title.txt").contains('FULL BUILD') 
						}
					}				
				}
			steps {
				dir("${env.WORKSPACE}\\Products\\Wachovia\\build") {
					bat  "choco pack  ./pack/wm_wachoviacode/wm_wachoviacode.nuspec  --version=${env.SnapshotComponentVersion}"
				}
        	}
		}

		stage('Package Full Build') {
        	when {     
				anyOf { branch 'develop'; branch 'release/*' }				   
				expression {
					readFile("${env.WORKSPACE}/output/MR_Title.txt").contains('FULL BUILD')                
				}	
			}
			steps {
				dir("${env.WORKSPACE}\\Products\\Wachovia\\build") {
					bat  "choco pack  ./pack/wm_wachoviacode/wm_wachoviacode.nuspec  --version=${env.ComponentVersion}"
				}
			}
		}

	    stage('Build + Veracode') {
        	when {     
				anyOf { branch 'develop'; branch 'release/*' }			  
				expression {
					readFile("${env.WORKSPACE}/output/MR_Title.txt").contains('FULL BUILD')                       
				}	
			}
			 steps {
                script {  
                           build job: 'VeracodeScan', wait: false
                 }
              }
        }

	
		stage('Build + SonarQube analysis') {
        	when {     
				anyOf { branch 'develop'; branch 'release/*' }			  
				expression {
					readFile("${env.WORKSPACE}/output/MR_Title.txt").contains('FULL BUILD')                       
				}
			}
			 steps {
                script {  
                           build job: 'Envision_Sonar',  parameters: [[$class: 'StringParameterValue', name: 'WorkspaceDir', value: "${env.WORKSPACE}\\Products\\Wachovia\\build"],
							[$class: 'StringParameterValue', name: 'PROJECT_NAME', value:"${env.PROJECT_NAME}.XML"],
							[$class: 'StringParameterValue', name: 'COMPONENT', value: "${params.COMPONENT}"],
							[$class: 'StringParameterValue', name: 'COMPONENT_GROUP', value: "${params.COMPONENT_GROUP}"],
							[$class: 'StringParameterValue', name: 'ComponentVersion', value: "${env.ComponentVersion}"],
							[$class: 'StringParameterValue', name: 'MAJOR_VERSION', value: "${env.MAJOR_VERSION}"],
							[$class: 'StringParameterValue', name: 'MINOR_VERSION', value: "${env.MINOR_VERSION}"],							
							[$class: 'StringParameterValue', name: 'UPStreamBUILD_NUMBER', value: "${env.BUILD_NUMBER}"],
							[$class: 'StringParameterValue', name: 'SolutionDir', value: "${env.WORKSPACE}\\Products\\Wachovia"]							
							], wait: false
                 }
              }
        }

 /*  stage('Build + SonarQube analysis') {
	        when {     
				//expression { true }
				anyOf { branch 'develop'; branch 'release/*' }			  
				expression {
					readFile("${env.WORKSPACE}/output/MR_Title.txt").contains('FULL BUILD')                       
				}
			}			
			steps {
			  	dir("${env.WORKSPACE}\\Products\\Wachovia\\build") {
					withSonarQubeEnv('SonarQube AWS Server') {
*/						
					  // Due to SONARMSBRU-307 value of sonar.host.url and credentials should be passed on command line
					  //		  bat "\"${tool 'SonarScanner_MSBuild_2.3.2'}\\SonarQube.Scanner.MSBuild.exe \"  begin /k:%COMPONENT% /n:NAWM_%COMPONENT_GROUP%_%COMPONENT% /v:%ComponentVersion% /d:sonar.host.url=%SONAR_HOST_URL% /d:sonar.login=%SONAR_AUTH_TOKEN% /d:sonar.verbose=true /d:sonar.exclusions=\"**/Telerik/**/*.js,**/wiesshared/**/*.xsl,**/*.gif,**/*.jpg,**/*.bmp,**/*.xml\""
					  //		  bat "\"${tool 'msbuild'}\"  %PROJECT_NAME%.XML  /p:SolutionFolder=\"${env.WORKSPACE}\\Products\\Wachovia\",CURRENT_ENVISION_BUILD_VERSION=${env.ComponentVersion},MAJOR_VER=${env.MAJOR_VERSION},MINOR_VER=${env.MINOR_VERSION},BUILD_NUMBER=${env.BUILD_NUMBER}"
					  //		  bat "\"${tool 'SonarScanner_MSBuild_2.3.2'}\\SonarQube.Scanner.MSBuild.exe \"  end"
/*					}
				}
			}
	    }
*/
		stage('BAMS Snapshot') {
		  when {    
				anyOf { branch 'develop'; branch 'release/*' }							  
				not {
					expression {
							readFile("${env.WORKSPACE}/output/MR_Title.txt").contains('FULL BUILD') 
					}
				}
			}

			steps {
				dir("${env.WORKSPACE}\\Products\\Wachovia\\build") {
					powershell '''
						$apiKey = "s.tr.wmbot:$env:BAMS_CREDS"
						$nupkgName = "$env:COMPONENT.$env:SnapshotComponentVersion.nupkg"
						nuget push $nupkgName -Source $env:BAMSURI -ApiKey $apiKey
					'''
				}
			}
		}
       
		stage('BAMS FULL_BUILD') {
		  when {     
				anyOf { branch 'develop'; branch 'release/*' }				   
				expression {
					readFile("${env.WORKSPACE}/output/MR_Title.txt").contains('FULL BUILD')                
				}		
			}
            
			steps {
				dir("${env.WORKSPACE}\\Products\\Wachovia\\build") {
					powershell '''
						$apiKey = "s.tr.wmbot:$env:BAMS_CREDS"
						$nupkgName = "$env:COMPONENT.$env:ComponentVersion.nupkg"
						nuget push $nupkgName -Source $env:BAMSURI -ApiKey $apiKey
					'''					
				}
			 }
		}

		stage('Update Hieradata, r10K and CDA' ){
        	when {   
				//expression { true }
				branch 'develop'		   
				expression {
					readFile("${env.WORKSPACE}/output/MR_Title.txt").contains('FULL BUILD')                
				}	
			}
			environment { 
                    ReleaseNoteURL = "${env.BUILD_URL}changes?BAMSVersion=${env.ComponentVersion}"
				}

			steps{
				dir("${env.WORKSPACE}") {
				   powershell '& "./build/scripts/UpdateComponentSSHEnvision.ps1" -ComponentGroup $env:COMPONENT_GROUP  -Platform $env:CDA_PLATFORM -ComponentName $env:COMPONENT -ComponentVersion $env:ComponentVersion -JenkinsWorkspace $env:WORKSPACE -HieraProjectName $env:HIERADATA_PROJECT -R10KProjectName $env:R10K_PROJECT -HieraVersionName $env:HIERA_VERSION_NAME -CompassApiKey $env:COMPASS_API_KEY -ReleaseNotesURL $env:ReleaseNoteURL -QualityGate $env:QualityGate -VersionValidated  "new"'
				}
			}
		}

		stage('Update Release Hieradata, r10K and CDA' ){
        	when {   
				branch 'release/*'			   
				expression {
					readFile("${env.WORKSPACE}/output/MR_Title.txt").contains('FULL BUILD')                
				}	
			}
			environment { 
                    ReleaseNoteURL = "${env.BUILD_URL}changes?BAMSVersion=${env.ComponentVersion}"
				}

			steps{
				dir("${env.WORKSPACE}") {
				    powershell '& "./build/scripts/UpdateComponentSSHEnvision.ps1" -ComponentGroup $env:COMPONENT_GROUP  -Platform $env:CDA_PLATFORM -ComponentName $env:COMPONENT -ComponentVersion $env:ComponentVersion -JenkinsWorkspace $env:WORKSPACE -HieraProjectName $env:HIERADATA_PROJECT -R10KProjectName $env:R10K_PROJECT -HieraVersionName $env:HIERA_VERSION_NAME -CompassApiKey $env:COMPASS_API_KEY -ReleaseNotesURL $env:ReleaseNoteURL -QualityGate $env:QualityGate -VersionValidated  "new"'
				}
			}
		}

		stage('RunDeck for Full Build') {
		  when {     
			  //	expression { true }	   			  
				anyOf { branch 'develop'; branch 'release/*' }			   
				expression {
					readFile("${env.WORKSPACE}/output/MR_Title.txt").contains('FULL BUILD')     
				}
							
			}
			steps {
				dir("${env.WORKSPACE}\\Products\\Wachovia\\build") {
					sleep time: 15, unit: 'MINUTES'				    
					powershell '''
						$header = @{'x-rundeck-auth-token' = 'NdSZuaSReZyqgniQi1TbfrSxfvbac54M'}
						Invoke-RestMethod "https://nonprod-sharedrundeck-api.int.thomsonreuters.com/api/20/job/$env:RUNDECK_UUID/run?nosso=" -Method Post -ContentType 'application/json' -Headers $header
					'''
				}
			}
		}
	
/*		stage('Tagging') {
			when {     
				anyOf { branch 'develop'; branch 'release/*' }				   
				expression {
					readFile("${env.WORKSPACE}/output/MR_Title.txt").contains('FULL BUILD')                
				}		
			}

			steps {
				dir("${env.WORKSPACE}\\${env.PROJECT_NAME}") {
					
					bat '''
						git config --global user.email 's.tr.wmbot@thomsonreuters.com'
						git config --global user.name 's.tr.wmbot'
						git tag -a '%ComponentVersion%' -m 'Jenkinstesting'
						git push --tags "https://%GIT_CREDS%@git.sami.int.thomsonreuters.com/NAWM-WealthTools/WM_WachoviaCode.git"
					'''
				}
			}
		}
*/
    }
    
	post {
       always {
        /// clean up the file
            dir("${env.WORKSPACE}\\output") {
                deleteDir()
            }
        }  		
		failure {
			updateGitlabCommitStatus name: 'build', state: 'failed'
    				
			slackSend teamDomain: "thomson-reuters", tokenCredentialId: "Slack_API_Token", channel: "#envision_devops", color: "#c93b23", message: "Build Failed: ${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>) \n\n" + editChangeSet.getChangeString()
		}

		success {
			updateGitlabCommitStatus name: 'build', state: 'success'

			script {
	/*			if(env.BRANCH_NAME == 'develop') {
					emailext (
						to: "${params.EMAIL_LIST}", 
						subject: "(${env.ComponentVersion}) - SUCCESS (${env.JOB_NAME})", 
						body: "Changes:\n " + editChangeSet.getChangeString() + "\n\n Check console output at: ${env.BUILD_URL}console." + "\n\n Please go to https://compass.thomsonreuters.com/release/releases?platform=wealth_management&componentsourceids=wm_envision.~ to check the deployment status \n"
					)
				}
				else {
					emailext (
						to: "${params.EMAIL_LIST}", 
						subject: "(${env.ComponentVersion}) - SUCCESS (${env.JOB_NAME})", 
						body: "Changes:\n " + editChangeSet.getChangeString() + "\n\n Check console output at: ${env.BUILD_URL}console." + "\n"
					)
				}
	*/
				slackSend teamDomain: "thomson-reuters", tokenCredentialId: "Slack_API_Token", channel: "#envision_devops", color: "#c93b23", message: "Build Success: ${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>) \n\n" + editChangeSet.getChangeString()	
			}
		}
  	}	
}
@NonCPS
def isManualBuild() {
	def cause = currentBuild.rawBuild.getCause(hudson.model.Cause$UserIdCause)
	if (cause) {
		return true
	}
	return false
}

def isJobStartedByTimer() {
    def startedByTimer = false
    try {
		def causeTimerTrigger = currentBuild.rawBuild.getCause(hudson.triggers.TimerTrigger$TimerTriggerCause)
		if (causeTimerTrigger) {
			 echo "causeTimerTrigger"
			 startedByTimer = true
		}
    } catch(theError) {
        echo "Error getting build cause"
    }
 
    return startedByTimer
}

def getComponentVersion() {
	if ( readFile("${env.WORKSPACE}/output/MR_Title.txt").contains("FULL BUILD") ) {
		return "${params.COMPONENTVERSION}.${env.BUILD_NUMBER}"
	}
	else 
	{
		return "${params.COMPONENTVERSION}.${env.BUILD_NUMBER}-snapshot"
	}
}
