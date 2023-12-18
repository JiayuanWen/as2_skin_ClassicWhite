#!/bin/bash
RED='\e[1;31m'
GREEN='\e[1;32m'
RESETFONT='\e[0m'

set -e
echo

echo -ne "Checking & cleaning remaining folders from previous compilation... \r"
if [ -d ./classic\ \(white\) ]; then
	rm -r ./classic\ \(white\)
fi
echo -e "Checking & cleaning remaining folders from previous compilation... Done"

echo -ne "Creating folder for final project... \r"
mkdir ./classic\ \(white\);
echo  -e "Creating folder for final project... Done"

echo -ne "Copying model folder... \r"
cp -r ./models ./classic\ \(white\)/; 
echo -e "Copying model folder... Done"

echo -ne "Copying sound folder... \r"
cp -r ./sounds ./classic\ \(white\)/;
echo -e "Copying sound folder... Done"

echo -ne "Copying texture folder... \r"
cp -r ./textures ./classic\ \(white\)/;
echo -e "Copying texture folder... Done"

echo -ne "Copying skin lua script... \r"
cp ./classic\ \(white\).lua ./classic\ \(white\)/;
echo -e "Copying skin lua script... Done"

echo -ne "Copying LICENSE... \r"
cp ./LICENSE ./classic\ \(white\)/;
echo -e "Copying LICENSE... Done"

echo -ne "Copying tooltip files... \r"
cp ./tooltip_*.txt ./classic\ \(white\)/;
echo -e "Copying tooltip files... Done"

echo -ne "Copying thumbnails... \r"
cp ./uigraphic_big.jpg ./classic\ \(white\)/;
cp ./uigraphic.jpg ./classic\ \(white\)/;
cp ./workshop_image_640x360.jpg ./classic\ \(white\)/;
echo -e "Copying thumbnails... Done"

echo
echo "Which format do you want to archive the skin to ? (z for zip / t for tar)"
format=""
read -p "Format: " format 
if [[ "$format" == "t" ]]; then
	if type tar > /dev/null; then
		echo -ne "Write skin to archive... \r"
		tar -cvf classic_white.tar ./classic\ \(white\)
		echo -e "Write skin to archive... Done"
	else
		echo
		echo -e "${RED}Tool 'tar' not installed. Refer to https://www.tecmint.com/install-zip-and-unzip-in-linux/ to install said tool for your distro.${RESETFONT}"
		echo
		rm -rf ./classic\ \(white\)
		exit 1
	fi
fi
if [[ "$format" == "z" ]]; then
	if type zip > /dev/null; then
			echo -ne "Write skin to archive... \r"
			zip -r classic_white ./classic\ \(white\)
			echo -e "Write skin to archive... Done"
	else
		echo
		echo -e "${RED}Tool 'zip' not installed. Refer to https://linuxconfig.org/how-to-install-tar-gz-file-on-linux to install said tool for your distro.${RESETFONT}"
		echo
		rm -rf ./classic\ \(white\)
		exit 1
	fi
fi

rm -rf ./classic\ \(white\)
echo
echo -e "${GREEN}Skin compiled without error. An archive has been created in skin's repo directory.${RESETFONT}"
echo
exit 0
