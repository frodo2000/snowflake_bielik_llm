#!/bin/bash

while [ $# -gt 0 ]
do
	case "$1" in
		-hf_token) hf_token=$2;shift;;
		-snowflake_account) snowflake_account=$2;shift;;
		-snowflake_database) snowflake_database=$2; shift;;
		-snow_connection_name) snow_connection_name=$2; shift;;
		*) shift;;
    esac
    shift
done

collect_information(){
    echo -ne "Provide HuggingFace Token: "
    read hf_token
    echo -ne "Provide Snowflake Account Identifier: "
    read snowflake_account
    echo -ne "Provide Snowflake Database: "
    read snowflake_database
    echo -ne "Provide Snow Connection name: "
    read snow_connection_name
}

execute_with_status(){
    process_output=$($1 2>&1)

    if [ $? == 0 ]
    then
        echo "OK"
        if [[ -n "$process_output" ]]
        then
            echo "Process output: "
            echo "${process_output}"
        fi
    else
        echo "Failed"
        echo "Process output: ${process_output}"
        exit 1
    fi
}

while [ -z "${hf_token}" ] | [ -z "${snowflake_account}" ] | [ -z "${snowflake_database}" ]| [ -z "${snow_connection_name}" ]
do
    collect_information
done


snowflake_database_lowercase=${snowflake_database,,}
script_path=$PWD

echo "PREPARE PHASE"
echo "-------------"
echo ""

echo "Getting user from snow connection (connection confirmation could be required): "
snowlake_user=`snow connection list --format json | python3 -c "import sys, json; print([con['parameters']['user'] for con in json.load(sys.stdin) if con['connection_name']=='$snow_connection_name'][0])" 2>&1`
if [ -z "${snowlake_user}" ]
then
   echo "User not found for provided connection name"
    exit 1
fi

snowflake_user=MARCIN_MOLAK

echo "Creating new files from template: "
echo -ne "- Bielik_Service/bielik.yaml: "
execute_with_status "cp ./Bielik_Service/bielik.yaml.org ./Bielik_Service/bielik.yaml"
echo -ne "- Bielik_Setup_Scripts/0_base_structures.sql: "
execute_with_status "cp ./Bielik_Setup_Scripts/0_base_structures.sql.org ./Bielik_Setup_Scripts/0_base_structures.sql"
echo -ne "- Bielik_Setup_Scripts/0_base_structures.sql: "
execute_with_status "cp ./Bielik_Setup_Scripts/1_docker_container.sh.org ./Bielik_Setup_Scripts/1_docker_container.sh"
echo -ne "- Bielik_Setup_Scripts/2_service.sql: "
execute_with_status "cp ./Bielik_Setup_Scripts/2_service.sql.org ./Bielik_Setup_Scripts/2_service.sql"

echo ""
echo "Apply settings for yaml: "
echo -ne "- Bielik_Service/bielik.yaml: "
execute_with_status "sed -i -e s/<HFToken>/${hf_token}/g -e s/<SnowflakeAccountIdentifier>/${snowflake_account}/g -e s/<SnowflakeDatabase>/${snowflake_database}/g -e s/<SnowflakeDatabaseLowerCase>/${snowflake_database_lowercase}/g ./Bielik_Service/bielik.yaml"
echo -ne "- Bielik_Setup_Scripts/0_base_structures.sql: "
execute_with_status "sed -i -e s/<SnowflakeUser>/${snowlake_user}/g -e s/<SnowflakeDatabase>/${snowflake_database}/g ./Bielik_Setup_Scripts/0_base_structures.sql"
echo -ne "- Bielik_Setup_Scripts/1_docker_container.sh.org: "
execute_with_status "sed -i -e s/<SnowflakeAccountIdentifier>/${snowflake_account}/g -e s/<SnowflakeDatabaseLowerCase>/${snowflake_database_lowercase}/g -e s/<SnowConnectionName>/${snow_connection_name}/g ./Bielik_Setup_Scripts/1_docker_container.sh"
echo -ne "- Bielik_Setup_Scripts/2_service.sql: "
execute_with_status "sed -i -e s/<SnowflakeUser>/${snowlake_user}/g -e s/<SnowflakeDatabase>/${snowflake_database}/g -e s~<ScriptPath>~${script_path}~g ./Bielik_Setup_Scripts/2_service.sql"

echo ""
echo ""
echo "EXECUTE PHASE"
echo "-------------"
echo ""
echo -ne "Would you like to continue (Y/N): "
read continue_flag
if [ "${continue_flag^^}" != "Y" ]
then
    exit 1
else
    echo ""
fi
echo "Creating Snowflake base objects (connection confirmation could be required): "
execute_with_status "snow sql --connection $snow_connection_name --filename ./Bielik_Setup_Scripts/0_base_structures.sql"
echo "Creating Bielik container and sending it to Snowflake (connection confirmation could be required): "
chmod +x ./Bielik_Setup_Scripts/1_docker_container.sh
execute_with_status "./Bielik_Setup_Scripts/1_docker_container.sh"
echo "Sending yaml to Snowflake and creating service (connection confirmation could be required): "
execute_with_status "snow sql --connection $snow_connection_name --filename ./Bielik_Setup_Scripts/2_service.sql"
