#!/usr/bin/env bash

# ffmpeg -i "$1" -af "highpass=f=200,lowpass=f=3000" output.mp4

#!/usr/bin/env bash

ffmpeg -i "$1" -af "highpass=f=80,afftdn=nr=10:nf=-50,dynaudnorm=f=150:g=15" -c:v copy -c:a aac -b:a 192k -y output.mp4
