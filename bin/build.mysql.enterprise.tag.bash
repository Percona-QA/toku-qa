#! /bin/bash

# build TokuDB for a particular git tag


#if [ $# -eq 0 ]; then
#  echo "usage: build.mysql.enterprise.tag.bash <build-id> <git-tag>"
#  exit 1
#fi
#buildId=$1
#gitTag=$2

buildId=703rc0
gitTag=tokudb-7.0.3-rc.0
debugBuilds=N
communityBuilds=Y
deleteFiles=Y

get.make.mysql.bash

oauthFile=${HOME}/.ssh/github.oauth

if [ -e "$oauthFile" ] ; then
    echo "using oauth authentication"
    gitHubOauth=`cat ${HOME}/.ssh/github.oauth`
else
    echo "missing oauth file ${oauthFile}, exiting"
    exit 1
fi

# --github_use_ssh=1 to go back to ssh authentication

# build the enterprise editions
mkdir mysql-e; pushd mysql-e
../make.mysql.bash --mysql=mysql-5.5.30   --build_type=enterprise --github_token=${gitHubOauth} --tokudb_version=${buildId} --git_tag=${gitTag}
scp */*/*linux-x86_64.tar.gz tcallaghan@192.168.1.242:~
popd
if [ ${deleteFiles} == "Y" ]; then
    rm -rf mysql-e
fi

mkdir mariadb-e; pushd mariadb-e
../make.mysql.bash --mysql=mariadb-5.5.30 --build_type=enterprise --github_token=${gitHubOauth} --tokudb_version=${buildId} --git_tag=${gitTag}
scp */*/*linux-x86_64.tar.gz tcallaghan@192.168.1.242:~
popd
if [ ${deleteFiles} == "Y" ]; then
    rm -rf mariadb-e
fi

if [ ${debugBuilds} == "Y" ]; then
    mkdir mysql-e-debug; pushd mysql-e-debug
    ../make.mysql.bash --mysql=mysql-5.5.30   --build_type=enterprise --github_token=${gitHubOauth} --build_debug=1 --tokudb_version=${buildId} --git_tag=${gitTag}
    scp */*/*linux-x86_64.tar.gz tcallaghan@192.168.1.242:~
    popd
    if [ ${deleteFiles} == "Y" ]; then
        rm -rf mysql-e-debug
    fi
    
    mkdir mariadb-e-debug; pushd mariadb-e-debug
    ../make.mysql.bash --mysql=mariadb-5.5.30 --build_type=enterprise --github_token=${gitHubOauth} --build_debug=1 --tokudb_version=${buildId} --git_tag=${gitTag}
    scp */*/*linux-x86_64.tar.gz tcallaghan@192.168.1.242:~
    popd
    if [ ${deleteFiles} == "Y" ]; then
        rm -rf mariadb-e-debug
    fi
fi

# build the community editions
if [ ${communityBuilds} == "Y" ]; then
    mkdir mysql; pushd mysql
    ../make.mysql.bash --mysql=mysql-5.5.30   --build_type=community --github_token=${gitHubOauth} --tokudb_version=${buildId} --git_tag=${gitTag}
    scp */*/*linux-x86_64.tar.gz tcallaghan@192.168.1.242:~
    popd
    if [ ${deleteFiles} == "Y" ]; then
        rm -rf mysql
    fi

    mkdir mariadb; pushd mariadb
    ../make.mysql.bash --mysql=mariadb-5.5.30 --build_type=community --github_token=${gitHubOauth} --tokudb_version=${buildId} --git_tag=${gitTag}
    scp */*/*linux-x86_64.tar.gz tcallaghan@192.168.1.242:~
    popd
    if [ ${deleteFiles} == "Y" ]; then
        rm -rf mariadb
    fi

    if [ ${debugBuilds} == "Y" ]; then
        mkdir mysql-debug; pushd mysql-debug
        ../make.mysql.bash --mysql=mysql-5.5.30   --build_type=community --github_token=${gitHubOauth} --build_debug=1 --tokudb_version=${buildId} --git_tag=${gitTag}
        scp */*/*linux-x86_64.tar.gz tcallaghan@192.168.1.242:~
        popd
        if [ ${deleteFiles} == "Y" ]; then
            rm -rf mysql-debug
        fi
    
        mkdir mariadb-debug; pushd mariadb-debug
        ../make.mysql.bash --mysql=mariadb-5.5.30 --build_type=community --github_token=${gitHubOauth} --build_debug=1 --tokudb_version=${buildId} --git_tag=${gitTag}
        scp */*/*linux-x86_64.tar.gz tcallaghan@192.168.1.242:~
        popd
        if [ ${deleteFiles} == "Y" ]; then
            rm -rf mariadb-debug
        fi
    fi
fi

scp */*/*/*linux-x86_64.tar.gz tcallaghan@192.168.1.242:~
