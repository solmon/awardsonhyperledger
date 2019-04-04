#!/bin/bash

echo
echo " ____    _____      _      ____    _____ "
echo "/ ___|  |_   _|    / \    |  _ \  |_   _|"
echo "\___ \    | |     / _ \   | |_) |   | |  "
echo " ___) |   | |    / ___ \  |  _ <    | |  "
echo "|____/    |_|   /_/   \_\ |_| \_\   |_|  "
echo
echo "Build your Employee Awards network (ean) end-to-end test"
echo
CHANNEL_NAME="$1"
DELAY="$2"
: ${CHANNEL_NAME:="EmployeeAwardsChannel"}
: ${TIMEOUT:="60"}
COUNTER=1
MAX_RETRY=5
ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/employeeawards.com/orderers/orderer.employeeawards.com/msp/tlscacerts/tlsca.employeeawards.com-cert.pem

echo "Channel name : "$CHANNEL_NAME

# verify the result of the end-to-end test
verifyResult () {
	if [ $1 -ne 0 ] ; then
		echo "!!!!!!!!!!!!!!! "$2" !!!!!!!!!!!!!!!!"
    echo "========= ERROR !!! FAILED to execute End-2-End Scenario ==========="
		echo
   		exit 1
	fi
}
#/solmon/work/hyperledger/healthclaims/hlfv16/composer/cypto-config
setGlobals () {

	if [ $1 -eq 0 -o $1 -eq 1 ] ; then
		CORE_PEER_LOCALMSPID="employeeawardsMSP"
		CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/employeeawards.com/peers/peer0.employeeawards.com/tls/ca.crt
		CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/employeeawards.com/users/Admin@employeeawards.com/msp		
		if [ $1 -eq 0 ]; then
			CORE_PEER_ADDRESS=peer0.employeeawards.com:7051
		else
			CORE_PEER_ADDRESS=peer1.employeeawards.com:7051
			CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/employeeawards.com/users/Admin@employeeawards.com/msp			
		fi
	else if [ $1 -eq 2 -o $1 -eq 3 ] ; then
		CORE_PEER_LOCALMSPID="teksystemsMSP"
		CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/teksystems.com/peers/peer0.teksystems.com/tls/ca.crt
		CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/teksystems.com/users/Admin@teksystems.com/msp
		if [ $1 -eq 2 ]; then
			CORE_PEER_ADDRESS=peer0.teksystems.com:7051
		else
			CORE_PEER_ADDRESS=peer1.teksystems.com:7051
		fi
	else
		CORE_PEER_LOCALMSPID="cubesystemsMSP"
		CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/cubesystems.com/peers/peer0.cubesystems.com/tls/ca.crt
		CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/cubesystems.com/users/Admin@cubesystems.com/msp
		if [ $1 -eq 2 ]; then
			CORE_PEER_ADDRESS=peer0.cubesystems.com:7051
		else
			CORE_PEER_ADDRESS=peer1.cubesystems.com:7051
		fi
	fi

	env |grep CORE
}

instantiateChaincode () {
	
	PEER=$1
	setGlobals $PEER
	# while 'peer chaincode' command can get the orderer endpoint from the peer (if join was successful),
	# lets supply it directly as we know it using the "-o" option
	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer chaincode instantiate -o orderer.employeeawards.com:7050 -C $CHANNEL_NAME -n mycc -v 1.0 -c '{"Args":["init","a","100","b","200"]}' -P "OR	('employeeawardsMSP.member','teksystemsMSP.member','cubesystemsMSP.member')" >&log.txt
	else
		peer chaincode instantiate -o orderer.employeeawards.com:7050 --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mycc -v 1.0 -c '{"Args":["init","a","100","b","200"]}' -P "OR	('employeeawardsMSP.member','teksystemsMSP.member','cubesystemsMSP.member')" >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Chaincode instantiation on PEER$PEER on channel '$CHANNEL_NAME' failed"
	echo "===================== Chaincode Instantiation on PEER$PEER on channel '$CHANNEL_NAME' is successful ===================== "
	echo
}

chaincodeQuery () {
  PEER=$1
  echo "===================== Querying on PEER$PEER on channel '$CHANNEL_NAME'... ===================== "
  setGlobals $PEER
  local rc=1
  local starttime=$(date +%s)

  # continue to poll
  # we either get a successful response, or reach TIMEOUT
  while test "$(($(date +%s)-starttime))" -lt "$TIMEOUT" -a $rc -ne 0
  do
     sleep $DELAY
     echo "Attempting to Query PEER$PEER ...$(($(date +%s)-starttime)) secs"
     peer chaincode query -C $CHANNEL_NAME -n mycc -c '{"Args":["query","a"]}' >&log.txt
     test $? -eq 0 && VALUE=$(cat log.txt | awk '/Query Result/ {print $NF}')
     test "$VALUE" = "$2" && let rc=0
  done
  echo 
  cat log.txt
  if test $rc -eq 0 ; then
	echo "===================== Query on PEER$PEER on channel '$CHANNEL_NAME' is successful ===================== "
  else
	echo "!!!!!!!!!!!!!!! Query result on PEER$PEER is INVALID !!!!!!!!!!!!!!!!"
        echo "================== ERROR !!! FAILED to execute End-2-End Scenario =================="
	echo
	exit 1
  fi
}

#instantiateChaincode 2

#Query on chaincode on Peer0/teksystems
echo "Querying chaincode on teksystems/peer0..."
#chaincodeQuery 0 100
chaincodeQuery 3 90

echo
echo "========= All GOOD, Healthwise Network execution completed =========== "
echo

echo
echo " _____   _   _   ____   "
echo "| ____| | \ | | |  _ \  "
echo "|  _|   |  \| | | | | | "
echo "| |___  | |\  | | |_| | "
echo "|_____| |_| \_| |____/  "
echo

exit 0
