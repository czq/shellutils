#!/bin/bash

## About this script
about() {
cat <<- EOF
IDL compiler, version 0.1
Copyright (c) 2014 Chen Zhiqiang <chenzhiqiang@mail.com>. Released under the MIT license.

EOF
}

## Usage for this script
help() {
about
cat <<- EOF
This script wrap the JDK's idlj and provide some extra functions:
  - Accept multiple files and directories containing IDL definitions to compile;
  - Manually specify java package prefix or auto detect from the "#pragma prefix" pragma.

Compiler Usage:
  $0 [options] -- <IDL files/dirs>

Where <IDL files/dirs> is list of a files or directories containing IDL definitions, it is required and must appear after the argument "--".

Options:
Accept all options of JDK's idlj, but provide extra options list below:
--help
  Show this usage.
--pkg-pragma
  Using the "#pragma prefix" pragma in an IDL file to specify the package name.
--pkg-prefix=<package_prefix>
  With this option to specify a package prefix for the generated Java classes.

Examples:
  $0 --pkg-pragma -- *.idl
  $0 --pkg-prefix=my.pkg -- dir1/*.idl dir2/*.idl
  $0 -emitAll -fall -i /idl/inc --pkg-pragma -- \$(find . -name "*.idl")
  find src/idl/ -name "*.idl" -maxdepth 1 | xargs $0 -td /target --pkg-prefix=my.pkg --

EOF
}

## Get the "#pragma prefix" pragma info from IDL file
pragmaPrefix() {
	awk '/^#pragma[[:space:]]+prefix[[:space:]]+/ {gsub(/[\"\r]+/,"",$3);print $3;}' $1 2>/dev/null
}
## Get the "module" name from IDL file
moduleName() {
	awk '/^module[ \t]+/ {gsub(/[\r\{]+/,"",$2);print $2;}' $1 2>/dev/null
}
## Reverse pragma prefix name to java package name (e.g., reversePackageName pkg.example.com => com.example.pkg)
reversePackageName() {
	echo $1 | awk -F'.' '{for(i=NF;i>0;i--){printf("%s%s",$i,i==1?"":".");}}'
}

if [[ $# -eq 0 ]] || echo " $* " | grep -qi -E '[[:space:]](--help)|(--usage)|(-h)[[:space:]]' ; then
	help && exit 0
fi

IDLS=() INCS=(.)
V=($@)
ARGS=()
PKG_PREFIX=""

for (( i=0; i<$#; i++ )) do
	case ${V[i]} in
	--pkg-pragma)
		PKG_PREFIX="#"
		;;
	--pkg-prefix)
		PKG_PREFIX=${V[++i]}
		;;
	--pkg-prefix=*)
		PKG_PREFIX=${V[i]#*=}
		;;
	--)
		IDLS=${V[@]:i+1}
		break
		;;
	-i)
		INCS+=(${V[++i]})
		ARGS+=("-i" ${V[i]})
		;;
	*)
		ARGS+=(${V[i]})
		;;
	esac
done

if [[ -z ${IDLS} ]]; then
	echo IDL files/dirs must appear after argument '"--"'
	exit 1
fi

## Add package prefix to module name.
if [[ "$PKG_PREFIX" != "" ]]; then
	for F in `find ${IDLS[@]} ${INCS[@]} -type f -maxdepth 1` ; do
		M=$(moduleName $F)
		P=${PKG_PREFIX}
		if [[ "$M" != "" ]]; then
			if [[ "$P" == "#" ]]; then
				P=$(pragmaPrefix $F)
				P=$(reversePackageName $P)
			fi
			if [[ "$P" != "" ]]; then
				ARGS+=("-pkgPrefix $M $P")
			fi
		fi
	done
fi

echo "Call idlj with options: " ${ARGS[@]}
echo ......
for F in `find ${IDLS[@]} -type f -maxdepth 1` ; do
	echo Compile: $F
	idlj ${ARGS[@]} $F
done

exit $?
