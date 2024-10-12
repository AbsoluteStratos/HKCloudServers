#!/bin/bash
TMPDIR="/opt/tmp"
[ ! -z "$PORT" ] || PORT=2222;
[ ! -z "$HKMP_EXE" ] || HKMP_EXE="HKMPServer.exe";
[ ! -z "$HKMP_PBD" ] || HKMP_PBD="HKMPServer.pdb";
[ ! -z "$HKMP_HOME" ] || HKMP_HOME="/opt/hkmp";
LOG="${HKMP_HOME}/logs/server.log"

help() {
	echo "Usage:"
	echo "All commands sends to server by default. Check the official wiki for a complete list of commands."
	echo "Additional commands:"
	echo "start - start the server"
	echo "log - watch server log file"]
	echo "plugin-health  - install hkmp health plugin"
	echo "plugin-pouch  - install hkmp pouch plugin"
	echo "plugin-trail  - install hkmp trail plugin"
	echo "plugin @1 @2 @3 @3 - install hkmp plug in from repo. Params: author, github repo name, plugin zip file, (optional verison)"
}

log() {
	tail -n10 ${LOG}
}

# Args: Author, Github repo name, Plugin Zip file, (optional verison, default will use latest)
plugin() { 
	echo "Installing plugin $2 files..."
	USER="$1"
	REPO="$2"
	ZIPFILE="$3"

    if [[ -z "$4" ]]
		then
        VERSION=$(curl -s https://api.github.com/repos/$USER/$REPO/releases | egrep 'html_url.*tag' | awk -F\" '{print $4}' | cut -d\/ -f8 | head -n1);
	else
		VERSION="$4"
	fi
	echo "Found version $VERSION"

	mkdir -p ${TMPDIR}
	curl -o ${TMPDIR}/Plugin.zip -sOL https://github.com/$USER/$REPO/releases/download/$VERSION/$ZIPFILE;
	unzip -o ${TMPDIR}/Plugin.zip -d ${TMPDIR} && rm ${TMPDIR}/Plugin.zip;
	cp ${TMPDIR}/* ${HKMP_HOME}/;
	rm -rf ${TMPDIR}/*
    echo "Plugin installed $REPO - $VERSION";
}

start() {
	echo "Moving server files into home directory"
	cp -u -v ${HKMP_EXE} HKMPServer.exe
	cp -u -v ${HKMP_PBD} HKMPServer.pdb
	echo "Staring server..."
	mono ${HKMP_HOME}/HKMPServer.exe $PORT
}

watch() {
	tail -f ${LOG}
}

# https://ss64.com/bash/test.html
if [[ -z "$1" ]]
  then
    help;
else
	case "$1" in
        "start"  )
			start;;
		"log" )
			log;;
		"plugin" )
			plugin $2 $3 $4 $5;;
		"plugin-health" )
			plugin PrashantMohta HkmpPouch HkmpPouch.zip v1.0.0 # Force 1.0.0 here because Modlinks not updated
			plugin TheMulhima HKMP.HealthDisplay HKMP_HealthDisplay.zip;;
		"plugin-pouch" )
			plugin PrashantMohta HkmpPouch HkmpPouch.zip v1.0.0;; # Force 1.0.0 here because Modlinks not updated
		"plugin-trail" )
			plugin TheMathGeek314 PlayerTrail PlayerTrail.zip;;
		"watch" )
			watch;;
        "help"   )
			help;;
        *        )
			echo "Unknown command";;
	esac
fi