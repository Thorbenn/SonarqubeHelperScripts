#!/bin/bash

#############################################################################################
# Description:                                                                              #
# A simple script that can be added to any CI/CD Pipeline for                               #
# checking if the Quality Gate of the Branch or PR was passed                               #
# If the Quality Gate is passed the script will exit with Exit Code 0                       #
# When the Quality Gate is not passed it will exit with Exit Code 1                         #
#                                                                                           #
# Requirements:                                                                             #
# jq and curl must be installed to interpret the Rest Response                              #
#                                                                                           #
# Parameters:                                                                               #
# 1 - The API Token needed to connect to Sonarqube                                          #
# 2 - The BaseURL with / at the End of your Sonarqube Instance                              #
#      Example: https://127.0.0.1:9000/                                                     #
# 3 - The Project Key of your Sonarqube Project                                             #
# 4 - The Branch's Name to get the results from                                             #
#                                                                                           #
# Usage Example:                                                                            #
# bash sonarqube_quality_gate.sh "MYTOKEN" "http://127.0.0.1:9000/" "MyProjectKey" "main"   #
#############################################################################################

#take the token from the parameter variable and encode it to base64
token=$1
tokenBase64=$(echo $token | base64)
#put the base url into a more understandable variable for further processing
baseUrl=$2
#same for the project key and branchname
projectKey=$3
branchName=$4

#Putting the URL together which is added to the Scripts Result Output
sonarqubeProjectUrl="${baseUrl}dashboard?id=${projectKey}"

#Refine the Branchname, so that it only has the branch name or pr number
branchName=$(echo "$branchName" | sed "s/refs\/pull\///g")
branchName=$(echo "$branchName" | sed "s/merge\///g")
branchName=$(echo "$branchName" | sed "s/refs\/heads\///g")

#The Variable we are going to use to build the propper rest call with
#if this is empty then something went wrong in our logics
url=""

#if branchName is numeric then its a pr
if [[ $branchName =~ ^[0-9]+$ ]]; then
      
      #its numeric therefore create the sonarqube url for a pr
      url="${baseUrl}api/qualitygates/project_status?projectKey=${projectKey}&pullRequest=${branchName}"   
else
      #its not numeric therefore create the sonarqube url for a branch
      url="${baseUrl}api/qualitygates/project_status?projectKey=${projectKey}&branch=${branchName}"
fi

#make the rest call to sonarqube to get the qualityGate of the branch or PR
projectStatus=$(curl -X GET $url -u $token: -H "Content-Type: application/json" 2> /dev/null)

#get the qualitygate status from the returned json 
qualityGate=$(echo $projectStatus | jq -r '.projectStatus.status')



if [ "$qualityGate"=="ERROR" ]; then
	echo "############################"
	echo "# Quality Gate: NOT PASSED #"
	echo "############################"
	echo "Quality Gate not passed for Branch/PR: ${branchName}"
	echo "Please check the Issues in Sonarqube: ${sonarqubeProjectUrl}"
	#exit with exit code 1 due to Quality Gate not being passed
	exit 1
else
	echo "########################"
	echo "# Quality Gate: PASSED #"
	echo "########################"
	echo "Quality Gate passed for Branch/PR: ${branchName}"
	echo "Sonarqube Project URL: ${sonarqubeProjectUrl}"
	exit 0
fi
