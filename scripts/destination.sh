case $1 in
  ("iOSTests") SIMULATOR='NetcoTests/iPhone-7/iOS/10.3' ;;
  ("tvOSTests") SIMULATOR='NetcoTests/Apple-TV-1080p/tvOS/10.2' ;;
  ("macOSTests") echo "platform=macOS,arch=x86_64"; exit 0 ;;
  (*) exit -1 ;;
esac

echo "id=$(./scripts/create_simulator.sh $SIMULATOR)"
