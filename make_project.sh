#!/bin/bash
# USAGE: ./make_project.sh <projectName> <bundle_id>
# Must be run from the directory containing CodeaTemplate
# Needs a lot of work - including Icons, setting bundle id, installing codea project, etc

cp -r CodeaTemplate "$1"
sed -i .bak "s/___PROJECTNAME___/$1/g" "$1/CodeaTemplate.xcodeproj/project.pbxproj"
rm "$1/CodeaTemplate.xcodeproj/project.pbxproj.bak"

sed -i .bak "s/___PROJECTNAME___/$1/g" "$1/CodeaTemplate.xcodeproj/xcshareddata/xcschemes/CodeaTemplate.xcscheme"
rm "$1/CodeaTemplate.xcodeproj/xcshareddata/xcschemes/CodeaTemplate.xcscheme.bak"


#Copy Resources over
#cp $ICON_FILE "$1/Icon.png"
