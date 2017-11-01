case $1 in
  ("iOSTests") SIMULATOR='NetcoTests/iPhone-7/iOS/11.1' ;;
  ("tvOSTests") SIMULATOR='NetcoTests/Apple-TV-1080p/tvOS/11.1' ;;
  ("macOSTests") echo "platform=macOS,arch=x86_64"; exit 0 ;;
  (*) exit -1 ;;
esac

echo "id=$(./scripts/create_simulator.sh $SIMULATOR)"
