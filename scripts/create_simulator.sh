source "$(dirname "$0")/common.sh"

function simulator_udid() {
  xcrun simctl list --json | jq ".devices[][] | select(.name==\"$1\") | .udid" --raw-output
}

function create_simulator_if_needed() {
  SIMULATOR=$1
  DEVICE=`device_for_simulator $1`
	OS=`os_for_simulator $1`	
  VERSION_SUFFIX=`version_suffix_for_simulator $1`
  RUNTIME=`runtime_for_simulator $1`

  local udid=`simulator_udid "${SIMULATOR}"`
  if [ -z `simulator_udid "${SIMULATOR}"` ]; then
    xcrun simctl create "${SIMULATOR}" "com.apple.CoreSimulator.SimDeviceType.${DEVICE}" "${RUNTIME}"
    local udid=`simulator_udid "${SIMULATOR}"`
    open -a "$(xcode-select -p)/Applications/Simulator.app" --args -CurrentDeviceUDID $udid
    while [ $(xcrun simctl list --json | jq ".devices[][] | select(.udid==\"$udid\") | .state" --raw-output) != "Booted" ]
    do
      sleep 10
    done
  else
    echo $udid
  fi
}

create_simulator_if_needed $1
