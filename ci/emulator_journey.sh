#!/usr/bin/env bash
# Placeholder until the integration journey exists (filled in later).
set +e
adb devices > ../journey.txt 2>&1
echo "journey=0" >> ../status.txt
