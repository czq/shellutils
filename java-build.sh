#!/bin/sh
about() {
cat <<- EOF
Java build script, version 0.1
Copyright (c) 2014 Chen Zhiqiang <chenzhiqiang@mail.com>. Released under the MIT license.

EOF
}

project_name=${project_name:-sample-app}
project_version=${project_version:-1.0-SNAPSHOT}

main_src=src/main/java
main_res=src/main/resources
main_out=target/classes

test_src=src/test/java
test_res=src/test/resources
test_out=target/test-classes

_CLASSPATH=${CLASSPATH:-.}

## Usage for this script
help() {
about
cat <<- EOF
Main targets:
 clean: clean the output files
 compile: compile main sources
 compile_tests: compile tests
 jar: build the jar file
 javadoc: generates the Javadoc
EOF
}

classpath() {
	find lib -print0 2>/dev/null | xargs -0 | sed "s/ /:/g"
}

task_clean() {
	echo clean the output files
	rm -rf target/
}

task_compile() {
	echo compile: compile main sources
	CLASSPATH=$(classpath):${_CLASSPATH}
	[[ -d $main_out ]] || mkdir -p $main_out
	find $main_src -name "*.java" -type f -print0 | xargs -0 javac -g:none -d $main_out
	cp -R $main_res/ $main_out
}

task_compile_tests() {
	task_compile
	echo compile_tests: compile tests
	CLASSPATH=${main_out}:$(classpath):${_CLASSPATH}
	find $test_src -name "*.java" -type f -print0 | xargs -0 javac -g -d $test_out
	cp -R $test_res/ $test_out
}

task_jar() {
	task_compile
	echo package: build the jar for the application
	jar -cf target/${project_name}-${project_version}.jar -C ${main_out} .
}

task_javadoc() {
	echo javadoc: generates the Javadoc of the application
	find $main_src -name "*.java" -print0 | xargs -0 javadoc -d target/apidocs
}

case $1 in
help)
	help ;;
clean)
	task_clean ;;
compile)
	task_compile ;;
compile_tests)
	task_compile_tests ;;
jar)
	task_jar ;;
javadoc)
	task_javadoc ;;
*)
	about
	task_jar
	;;
esac
