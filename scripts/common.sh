function device_for_simulator() {
  echo "$1" | cut -d "/" -f 2
}

function os_for_simulator() {
  echo "$1" | cut -d "/" -f 3
}

function version_suffix_for_simulator() {
  echo "$1" | cut -d "/" -f 4 | sed -e "s/\./-/"
}

function runtime_for_simulator() {
  OS=`os_for_simulator $1`
  OVERSION_SUFFIXS=`version_suffix_for_simulator $1`
  echo "com.apple.CoreSimulator.SimRuntime.${OS}-${VERSION_SUFFIX}"
}
