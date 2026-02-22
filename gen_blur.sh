#!/bin/bash
FONT_SIZE=18
FONT="Segoe-UI"
SCRIPT_FILE="PlymouthVista.script"  

config_keys=("ShutdownText" "UpdateTextMTL" "RebootText" "LogoffText")
declare -A config_values

if ! [ -f $SCRIPT_FILE ] ; then
    echo "No PlymouthVista.script found! Make sure to run this after compilation."
    exit 1
fi

if [[ ! -f "pv_conf.sh" ]]; then
    echo "No pv_conf.sh found! Stopping!"
    exit 1
fi

for key in ${config_keys[@]}; do
    config_values[$key]=$(./pv_conf.sh -g $key)
done

unformattedText=${config_values["UpdateTextMTL"]}

for i in {0..100}; do
    key="Update$i"
    value=$(echo $unformattedText | sed "s/"%i"/$i/g")
    config_values["$key"]="$value"
done

unset config_values["UpdateTextMTL"]

use_shadow=$(./pv_conf.sh -g UseShadow)

if [[ $use_shadow == 1 ]]; then
    echo "Generating images with shadows..."
else
    echo "Generating images without shadows..."
fi

for key in "${!config_values[@]}"; do
    value=${config_values[$key]}

    dimensions=$(magick -density 96 -font "$FONT" -pointsize "$FONT_SIZE" label:"$value" -format "%[fx:w]x%[fx:h]" info:)

    magick -density 96 -size "$dimensions" xc:none \
        -font "$FONT" -pointsize "$FONT_SIZE" \
        -fill white \
        -gravity center \
        -annotate +0+0 "$value" "./images/text$key.png"

    if [[ $use_shadow == 1 ]]; then
        magick "./images/text$key.png" \
            -bordercolor none -border 2 \
            -fill "rgb(20,20,20)" -colorize 100 \
            -blur 0x1 \
            -channel A -evaluate multiply 0.6 +channel \
            "./images/blur$key.png"
    fi
done

echo "Done."