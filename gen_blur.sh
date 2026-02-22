#!/bin/bash
FONT_SIZE=18
FONT="Segoe-UI"
SCRIPT_FILE="plymouth-vista.script"  

config_keys=("ShutdownText" "UpdateTextMTL" "RebootText" "LogoffText")
declare -A config_values

if ! [ -f $SCRIPT_FILE ] ; then
    echo "No plymouth-vista.script found! Make sure to run this after compilation."
    exit 1
fi

if [[ ! -f "pv_conf.sh" ]]; then
    echo "No pv_conf.sh found! Stopping!"
    exit 1
fi

for key in ${config_keys[@]}; do
    config_values[$key]=$(sh ./pv_conf.sh -g $key)
done

unformattedText=${config_values["UpdateTextMTL"]}

for i in {0..100}; do
    key="Update$i"
    value=$(echo $unformattedText | sed "s/"%i"/$i/g")
    config_values["$key"]="$value"
done

unset config_values["UpdateTextMTL"]

echo "Generating images..."

for key in "${!config_values[@]}"; do
    value=${config_values[$key]}

    dimensions=$(magick -density 96 -font "$FONT" -pointsize "$FONT_SIZE" label:"$value" \
    -format "%[fx:w+27]x%[fx:h+27]" info:)

    magick -density 96 -size "$dimensions" xc:none \
        -font "$FONT" -pointsize "$FONT_SIZE" \
        -fill white \
        -gravity center \
        -annotate +0+0 "$value" \
        -trim +repage "./images/${key}.png"

    magick "./images/${key}.png" \
        -bordercolor none -border 2 \
        -fill "rgb(20,20,20)" -colorize 100 \
        -blur 0x1 \
        -channel A -evaluate multiply 0.6 +channel \
        "./images/blur${key}.png"
done

echo "Done."