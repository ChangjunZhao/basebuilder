#!/bin/bash -el

function add_platform() {
	platform=$1
	echo "adding platform $platform..."
	tsuru-admin platform-add $platform -d https://raw.githubusercontent.com/tsuru/basebuilder/master/${platform}/Dockerfile
}

function test_platform() {
	platform=$1
	app_name=app-${platform}
	app_dir=/tmp/${app_name}
	echo "testing platform ${platform} with app ${app_name}..."

	if [ -d ${app_dir} ]
	then
		rm -rf ${app_dir}
	fi

	mkdir ${app_dir}
	git init ${app_dir}
	cp /tmp/basebuilder/examples/${platform}/* ${app_dir}
	git --git-dir=${app_dir}/.git --work-tree=${app_dir} add ${app_dir}/*
	git --git-dir=${app_dir}/.git --work-tree=${app_dir} commit -m "add files"

	tsuru app-create ${app_name} ${platform}
	git --git-dir=${app_dir}/.git --work-tree=${app_dir} push git@localhost:${app_name}.git master

	set +e
	for i in `seq 1 5`
	do
		output=`curl -m 5 -sNH "Host: ${app_name}.tsuru-sample.com" localhost`
		if [ $? == 0 ]
		then
			break
		fi
		sleep 5
	done
	msg=`echo $output | grep -q "Hello world from tsuru" || echo "ERROR: Platform $platform - Wrong output: $output"`
	set -e

	tsuru app-remove -ya ${app_name}

	if [ "$msg" != "" ]
	then
		echo >&2 $msg
		exit 1
	fi
}

function clone_basebuilder() {
	if [ -d $1 ]
	then
		rm -rf $1
	fi
	git clone https://github.com/tsuru/basebuilder.git $1
	git config --global user.email just_testing@tsuru.io
	git config --global user.name "Tsuru Platform Tests"
}

function clean_tsuru_now() {
	rm /tmp/tsuru-now.bash
	tsuru app-remove -ya tsuru-dashboard 2>/dev/null
	mongo tsurudb --eval 'db.platforms.remove({_id: "python"})'
	docker rmi -f tsuru/python 2>/dev/null
}

curl -sL https://raw.githubusercontent.com/tsuru/now/master/run.bash -o /tmp/tsuru-now.bash
bash /tmp/tsuru-now.bash "$@"

export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$PATH
export DOCKER_HOST="tcp://127.0.0.1:4243"

set +e
clean_tsuru_now
set -e

clone_basebuilder /tmp/basebuilder
echo -e "Host localhost\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config

platforms="buildpack nodejs php python python3 ruby ruby20 static lisp"

for platform in $platforms
do
	set +e
	add_platform $platform
	set -e

	test_platform $platform
done

rm -rf /tmp/basebuilder
rm -rf /tmp/app-*
