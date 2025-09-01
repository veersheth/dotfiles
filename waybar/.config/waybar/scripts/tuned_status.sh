#!/usr/bin/bash
profile=$(tuned-adm active | awk '{print $4}')
echo "{\"profile\": \"$profile\", \"icon\": \"$profile\"}"

