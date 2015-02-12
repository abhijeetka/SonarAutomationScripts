#!/bin/bash


##### Prerequisites for running this script #####

#1.	Script only runs on CentOS [RPM based systems].
#2.	Mysql-Server should already be installed and running.

##### Declare variables ##### 

ROOTPW=redhat
DBNAME=sonar
DBUSER=sonar
DBPASS=sonar
db="create database $DBNAME;create user $DBUSER;grant all on $DBNAME.* to '$DBUSER'@'localhost' identified by '$DBPASS';FLUSH PRIVILEGES;"
IPADDRESS=`ip route get 8.8.8.8 | awk '{ print $NF; exit }'`

##### Script to install SonarQube and Sonar-Runner and Configure them (On RPM based systems only) #####

if ! which java > /dev/null; then
   echo -e "Java is not installed!! \c"
   echo -e "Installing Java..."
   sleep 3
   printf "\n\n"
   yum -y install java-1.7.0-openjdk 
   printf "\n\n" 

else
   echo "Java is installed."
   printf "\n\n"
   sleep 3
fi

if ! which mysql > /dev/null; then
   echo -e "MySQL is not installed!! \c"
   echo -e "Installing MySQL..."
   sleep 3
   printf "\n\n"
   if [ $# -eq 0 ]; then
	 echo "No arguments supplied... Using default MySQL Root Password..."
     yum -y install mysql-server
     service mysqld start
	 mysqladmin -u root password "$ROOTPW"
     printf "\n\n"
	 
	 echo "**********************************************************************"
	 echo "Creating Sonar Database..."
	 echo "**********************************************************************"
     sleep 3
     printf "\n\n"

     mysql -u root -p$ROOTPW -e "$db"
   
   else 
     echo "Arguments Supplied... Using provided MySQL Password..."
	 yum -y install mysql-server
     service mysqld start
	 mysqladmin -u root password "$2"
	 printf "\n\n"
	 echo "**********************************************************************"
     echo "Creating Sonar Database..."
	 echo "**********************************************************************"
	 sleep 3
	 printf "\n\n"

	 mysql -u root -p$2 -e "$db"
   fi

else
   echo "MySQL is installed."
   sleep 3
   printf "\n\n"
   if [ $# -eq 0 ]; then
     echo "MySQL Password not supplied... Using default MySQL Password..."
     sleep 3
     printf "\n\n"  
     service mysqld start
 
     echo "**********************************************************************"
     echo "Creating Sonar Database..."
     echo "**********************************************************************"
     sleep 3
     printf "\n\n"
     mysql -u root -p$ROOTPW -e "$db"
	
   else
	 echo "MySQL Password Supplied... Using Supplied MySQL Password to create database..." 
     service mysqld start
	 echo "**********************************************************************"
     echo "Creating Sonar Database..."
     echo "**********************************************************************"
     sleep 3
     printf "\n\n"
     mysql -u root -p$2 -e "$db"
   fi 
fi

if ! which unzip > /dev/null; then
   echo -e "Unzip is not installed!! \c"
   echo -e "Installing Unzip..."
   sleep 3
   printf "\n\n"
   yum -y install unzip
   printf "\n\n"

else
   echo "Unzip is installed."
   printf "\n\n"
   sleep 3
fi


##### Add Sonar Repository #####

echo "**********************************************************************"
echo "Downloading Sonar..."
echo "**********************************************************************"
printf "\n"

wget -O /etc/yum.repos.d/sonar.repo http://downloads.sourceforge.net/project/sonar-pkg/rpm/sonar.repo

##### Install Sonar #####

echo "**********************************************************************"
echo "Installing Sonar..."
echo "**********************************************************************"
printf "\n"

yum -y install sonar

##### Take sonar configuration file backup and create a new one #####

cp /opt/sonar/conf/sonar.properties /opt/sonar/conf/sonar.properties.bkp

##### Insert values in sonar.properties file #####

echo -e "sonar.jdbc.username=$DBUSER\nsonar.jdbc.password=$DBPASS\n\nsonar.jdbc.url=jdbc:mysql://localhost:3306/$DBNAME?useUnicode=true&characterEncoding=utf8&rewriteBatchedStatements=true&useConfigs=maxPerformance\n\nsonar.jdbc.maxActive=20\nsonar.jdbc.maxIdle=5\nsonar.jdbc.minIdle=2\nsonar.jdbc.maxWait=5000\nsonar.jdbc.minEvictableIdleTimeMillis=600000\nsonar.jdbc.timeBetweenEvictionRunsMillis=30000\n\nsonar.web.host=$IPADDRESS\nsonar.web.port=9080" > /opt/sonar/conf/sonar.properties

##### Start Sonarcube #####

echo "**********************************************************************"
echo "Starting Sonar Application..."
echo "**********************************************************************"
printf "\n"

service sonar start

echo "**********************************************************************"
echo "Installed SonarQube"
echo "**********************************************************************"
printf "\n"

echo "**********************************************************************"
echo "Installing SonarRunner..."
echo "**********************************************************************"
printf "\n"


##### Install Sonar-Runner #####

##### Download and Unzip Sonar Runner #####
wget --directory-prefix=/opt http://repo1.maven.org/maven2/org/codehaus/sonar/runner/sonar-runner-dist/2.4/sonar-runner-dist-2.4.zip

unzip -d /opt /opt/sonar-runner-dist-2.4.zip

##### Take Sonar Runner configuration file backup and create a new one #####

cp /opt/sonar-runner-2.4/conf/sonar-runner.properties /opt/sonar-runner-2.4/conf/sonar-runner.properties.bkp

##### Insert values in sonar.properties file #####


echo -e "sonar.host.url=http://$IPADDRESS:9080\n\nsonar.jdbc.url=jdbc:mysql://localhost:3306/$DBNAME?useUnicode=true&amp;characterEncoding=utf8\n\nsonar.jdbc.username=$DBUSER\nsonar.jdbc.password=$DBPASS\n\nsonar.login=admin\nsonar.password=admin" > /opt/sonar-runner-2.4/conf/sonar-runner.properties

echo "export SONAR_RUNNER_HOME=/opt/sonar-runner-2.4" >> /etc/profile
echo "export PATH=${PATH}:/opt/sonar-runner-2.4/bin" >> /etc/profile
source /etc/profile

echo "**********************************************************************"
echo "Installed Sonar Runner"
echo "**********************************************************************"
