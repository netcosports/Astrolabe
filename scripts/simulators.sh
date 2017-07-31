IOS_SIMULATOR=NetcoTests/iPhone-7/iOS/10.3
TVOS_SIMULATOR=NetcoTests/Apple-TV-1080p/tvOS/10.2

function simulator_udid() {
  xcrun simctl list --json | jq ".devices[][] | select(.name==\"$1\") | .udid" --raw-output
}

function create_simulator_if_needed() {
  SIMULATOR=$1
  DEVICE=`echo "${SIMULATOR}" | cut -d "/" -f 2`
	OS=`echo "${SIMULATOR}" | cut -d "/" -f 3`
	VERSION_SUFFIX=`echo "${SIMULATOR}" | cut -d "/" -f 4 | sed -e "s/\./-/"`
  RUNTIME="com.apple.CoreSimulator.SimRuntime.${OS}-${VERSION_SUFFIX}"

  if [ -z `simulator_udid "${SIMULATOR}"` ]; then
    xcrun simctl create "${SIMULATOR}" "com.apple.CoreSimulator.SimDeviceType.${DEVICE}" "${RUNTIME}"
  fi
}

create_simulator_if_needed $IOS_SIMULATOR
create_simulator_if_needed $TVOS_SIMULATOR
