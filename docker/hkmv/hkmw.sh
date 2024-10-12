#!/bin/bash
TMPDIR="/opt/tmp"
[ ! -z "$PORT" ] || PORT=2222;
[ ! -z "$HKMW_OPT" ] || HKMW_OPT="/opt/hkmp";
[ ! -z "$HKMW_HOME" ] || HKMW_HOME="/opt/hkmp";
[ ! -z "$HKMW_SEVER_NAME" ] || HKMW_SEVER_NAME="Foo Server";
LOG="${HKMW_HOME}/logs/server.log"


execute() {
        STR="${@}"^M
        screen -S server -X stuff "$STR"
        sleep 1;
        tail -n1 ${LOG}
}

help() {
	echo "Usage:"
	echo "All commands sends to server by default. Check the official wiki for a complete list of commands."
	echo "Additional commands:"
	echo "start - start the server"
}

log() {
	tail -n10 ${LOG}
}

start() {
	echo "Moving server files into home directory"
	cp -u -v -r ${HKMW_OPT}/* ${HKMW_HOME}
	echo "Staring server..."
	echo "{'ListeningIP': '0.0.0.0', 'ListeningPort': ${PORT}, 'ServerName': '${HKMW_SEVER_NAME}'}" > ${HKMW_HOME}/config.json
	mono ${HKMW_HOME}/MultiWorldServer.exe
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
		"watch" )
			watch;;
        "help"   )
			help;;
        *        )
			execute ${@};;
	esac
fi
# [[ -f ${DIR}/${EXE} && -f ${DIR}/${PDB} ]] && start || update