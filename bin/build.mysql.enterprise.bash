#! /bin/bash

# build TokuDB via standard naming convention process.
#   used to create final release tarballs


#if [ $# -eq 0 ]; then
#  echo "usage: build.mysql.enterprise.bash <build-id>"
#  exit 1
#fi
#buildId=$1

buildId=7.0.3

debugBuilds=Y
communityBuilds=Y
deleteFiles=Y

get.make.mysql.bash

#searchString='\$ft_revision'
#sed -i "s/${searchString}/${buildId}/g" make.mysql.bash

oauthFile=${HOME}/.ssh/github.oauth

if [ -e "$oauthFile" ] ; then
    echo "using oauth authentication"
    gitHubOauth=`cat ${HOME}/.ssh/github.oauth`
else
    echo "missing oauth file ${oauthFile}, exiting"
    exit 1
fi

# --github_use_ssh=1 to go back to ssh authentication

buildDirName=mysql-e
mkdir ${buildDirName}; pushd ${buildDirName}
../make.mysql.bash --mysqlbuild=mysql-5.5.30-tokudb-${buildId}-e-linux-x86_64 --github_token=${gitHubOauth}
scp */*/*.tar.gz tcallaghan@192.168.1.242:~
popd
if [ ${deleteFiles} == "Y" ]; then rm -rf ${buildDirName}; fi

buildDirName=mariadb-e
mkdir ${buildDirName}; pushd ${buildDirName}
../make.mysql.bash --mysqlbuild=mariadb-5.5.30-tokudb-${buildId}-e-linux-x86_64 --github_token=${gitHubOauth}
scp */*/*.tar.gz tcallaghan@192.168.1.242:~
popd
if [ ${deleteFiles} == "Y" ]; then rm -rf ${buildDirName}; fi

if [ ${debugBuilds} == "Y" ]; then
    buildDirName=mysql-e-debug
    mkdir ${buildDirName}; pushd ${buildDirName}
    ../make.mysql.bash --mysqlbuild=mysql-5.5.30-tokudb-${buildId}-debug-e-linux-x86_64 --github_token=${gitHubOauth}
    scp */*/*.tar.gz tcallaghan@192.168.1.242:~
    popd
    if [ ${deleteFiles} == "Y" ]; then rm -rf ${buildDirName}; fi

    buildDirName=mariadb-e-debug
    mkdir ${buildDirName}; pushd ${buildDirName}
    ../make.mysql.bash --mysqlbuild=mariadb-5.5.30-tokudb-${buildId}-debug-e-linux-x86_64 --github_token=${gitHubOauth}
    scp */*/*.tar.gz tcallaghan@192.168.1.242:~
    popd
    if [ ${deleteFiles} == "Y" ]; then rm -rf ${buildDirName}; fi
fi


# build community edition
if [ ${communityBuilds} == "Y" ]; then
    buildDirName=mysql
    mkdir ${buildDirName}; pushd ${buildDirName}
    ../make.mysql.bash --mysqlbuild=mysql-5.5.30-tokudb-${buildId}-linux-x86_64 --github_token=${gitHubOauth}
    scp */*/*.tar.gz tcallaghan@192.168.1.242:~
    popd
    if [ ${deleteFiles} == "Y" ]; then rm -rf ${buildDirName}; fi

    buildDirName=mariadb
    mkdir ${buildDirName}; pushd ${buildDirName}
    ../make.mysql.bash --mysqlbuild=mariadb-5.5.30-tokudb-${buildId}-linux-x86_64 --github_token=${gitHubOauth}
    scp */*/*.tar.gz tcallaghan@192.168.1.242:~
    popd
    if [ ${deleteFiles} == "Y" ]; then rm -rf ${buildDirName}; fi

    if [ ${debugBuilds} == "Y" ]; then
        buildDirName=mysql-debug
        mkdir ${buildDirName}; pushd ${buildDirName}
        ../make.mysql.bash --mysqlbuild=mysql-5.5.30-tokudb-${buildId}-debug-linux-x86_64 --github_token=${gitHubOauth}
        scp */*/*.tar.gz tcallaghan@192.168.1.242:~
        popd
        if [ ${deleteFiles} == "Y" ]; then rm -rf ${buildDirName}; fi
    
        buildDirName=mariadb-debug
        mkdir ${buildDirName}; pushd ${buildDirName}
        ../make.mysql.bash --mysqlbuild=mariadb-5.5.30-tokudb-${buildId}-debug-linux-x86_64 --github_token=${gitHubOauth}
        scp */*/*.tar.gz tcallaghan@192.168.1.242:~
        popd
        if [ ${deleteFiles} == "Y" ]; then rm -rf ${buildDirName}; fi
    fi
fi
