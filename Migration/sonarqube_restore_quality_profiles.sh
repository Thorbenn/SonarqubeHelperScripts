#!/bin/bash

#########################################################################################################
# Description:                                                                                          #
# A script that Syncs a defined Set of Java Sonarqube Quality Profiles from one SQ Instance to another  #                       
#                                                                                                       #
# Parameters:                                                                                           #
# 1 - The BaseURl of the Main Server from which you want to sync                                        #
#     Example: http://mainqube:9000                                                                     #
# 2 - The API Key of the Main Server                                                                    #
# 3 - The BaseURl of the Minion Server to which you want to sync                                        #
#     Example: http://minionqube:9000                                                                   #
# 4 - The API Key of the Minion Server                                                                  #
#                                                                                                       #
# Example Call:                                                                                         #
# bash sonarqube_restore_quality_profiles.sh http://localhost:9000 key_1 http://localhost:9001 key_2    #
#########################################################################################################

# check the number of parameters passed to script
if [ $# != 4 ]
then
    echo "Incorrect Number of Parameters!"
    exit 1
fi

#save parameters to more speaking variables
mainUrl=$1
mainToken=$2
minionUrl=$3
minionToken=$4

#declare array of profiles that should be synced for a specific language
#java
declare -a javaProfiles=("test-profile" "test-profile2")

#backup and restore the java profiles
echo "###########################"
echo "#  Syncing JAVA Profiles  #"
echo "###########################"
for i in "${javaProfiles[@]}"
do
    #get the profile from the Main server
    curl "$mainUrl/api/qualityprofiles/backup?language=java&qualityProfile=$i" -u $mainToken: > profile.xml
    if [ $? == 0 ]
    then
        echo "Export of Profile $i successful!"
    else
        echo "Something went wrong during the Export of Profile $i, aborting Sync!"
        exit 1
    fi

    #restore the profile to the Minion server
    curl "$minionUrl/api/qualityprofiles/restore" -u $minionToken: -F "backup=@profile.xml" > Output.txt
    if [ $? == 0 ]
    then
        echo "Import of Profile $i successful!"
    else
        echo "Something went wrong during the Import of Profile $i, aborting Sync!"
        exit 1
    fi

done
