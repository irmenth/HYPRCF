#!/bin/bash

DIR=$HOME/Wallpapers/
PICS=($(ls ${DIR}))

RANDOMPICS=${PICS[ $RANDOM % ${#PICS[@]} ]}

swww query || swww init

#change-wallpaper using swww
swww img ${DIR}/${RANDOMPICS} --transition-fps 60 --transition-type grow --transition-pos top-right --transition-duration 1 --transition-bezier 0.43,1.19,1,0.4
