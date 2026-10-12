#!/bin/zsh
# record_take.sh <take>: records the stage while the driver plays recording/takes/<take>.json. Writes
# $DEMO_WORK/takes/<take>.mov, plus the recorder's and driver's timestamped logs that the edit is cut by.
# The take starts from whatever the app shows; record_all_takes.sh sets up each one's starting state.
set -e
source ${0:A:h:h}/settings.sh
name=$1
takes=$DEMO_WORK/takes
mkdir -p $takes
movie=$takes/$name.mov
rm -f $movie $movie.stop
$DEMO_WORK/bin/stage-recorder $movie 120 > $takes/$name.recorder.log 2>&1 &
recorder=$!
for _ in {1..100}; do grep -q "RECORDING STARTED" $takes/$name.recorder.log 2>/dev/null && break; sleep 0.1; done
grep -q "RECORDING STARTED" $takes/$name.recorder.log || { echo "recorder did not start"; kill $recorder; exit 1; }
sleep 0.6
driver_status=0
$DEMO_WORK/bin/demo-driver run $DEMO_VIDEO_TOOLS/recording/takes/$name.json > $takes/$name.driver.log 2>&1 \
  || driver_status=$?
sleep 0.8
touch $movie.stop
wait $recorder || true
rm -f $movie.stop
tail -3 $takes/$name.driver.log
echo "take $name: driver exit $driver_status, $(du -h $movie | cut -f1)"
exit $driver_status
