
# outpath
OUTPATH=$1
SCHEME=SyncPlayer_Tests
device=`xcrun xctrace list devices 2>&1 | grep -oE 'iPad.*.*Simulator.*1[3-9].*[)]+' | head -1 | grep -oE 'iPad.+?)' | head -1`
xcodebuild \
  -workspace Example/SyncPlayer.xcworkspace \
  -scheme $SCHEME \
  -sdk iphonesimulator \
  -destination "platform=iOS Simulator,name=$device" \
  test | xcbeautify > $OUTPATH
  TEST_TAIL=$(tail -n 2 $OUTPATH)

  PASSSTR='Test Succeeded'
  ISPASS=$(echo $TEST_TAIL | grep "${PASSSTR}")
  if [[ "$ISPASS" != "" ]]
  then
    echo "TEST Succeeded"
  else
    echo "TEST FAIL SEE $OUTPATH"
    exit 1
  fi
