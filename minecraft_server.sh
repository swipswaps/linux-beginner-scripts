#!/bin/bash

printf "\033c"

if [ "$(id -u)" != "0" ]; then
	echo -e "\n---------------------------------------------------------------------------------\n"
	echo -e "PLEASE EXECUTE THIS SCRIPT AS ROOT OR SUDO!\n"
	echo "sudo ${0}"
	echo -e "\n---------------------------------------------------------------------------------"
	exit 1
fi

DEPENDENCIES="screen openjdk-8-jre-headless"
dpkg -s $DEPENDENCIES &>/dev/null
if [ $? -ne 0 ]; then
	echo -e "For Minecraft to work we need to install the following dependencies:\n"
	for DEPENDENCY in $DEPENDENCIES; do
		echo "- $DEPENDENCY"
	done
	echo ""
	read -r -p "Please insert 'YES' to allow the installation. Otherwise this script will exit here: " ANSWER
	if [ "$ANSWER" == "YES" ]; then
		apt-get update
		apt-get -y install screen openjdk-8-jre-headless
		if [ $? -ne 0 ]; then
			echo -e "\n---------------------------------------------------------------------------------\n"
			echo "Installation failed, trying to fix..."
			echo -e "\n---------------------------------------------------------------------------------\n"
			sleep 3
			apt-get -f -y install
			if [ $? -ne 0 ]; then
				echo "Could not install dependencies. Will exit now."
				exit 1
			fi
		fi	
	else
		echo "Your answer was \"$ANSWER\" and not YES. So this script will exit now."
		exit 1
	fi
fi

USERNAME=""
while [ -z "$USERNAME" ]; do
	echo -e "---------------------------------------------------------------------------------\n"
	echo "Please insert your desired username that is used to manage the Minecraft server."
	echo -e "The server will get created in the home directory of the user entered.\n"
	read -r -p "The user gets created if it does not already exist: " USERNAME
done


id -g $USERNAME &>/dev/null
if [ $? -ne 0 ]; then
        groupadd "$USERNAME"
fi

id -u $USERNAME &>/dev/null
if [ $? -ne 0 ]; then
	echo -e "\n---------------------------------------------------------------------------------\n"
	echo "User does not exist! To create this user, we need a password!"
	echo -e "\n---------------------------------------------------------------------------------\n"
	PASSWORD=""
	while [ -z "$PASSWORD" ]; do
        	read -r -s -p "Please insert the desired password for User $USERNAME: " PASSWORD
	done
        useradd -g "$USERNAME" -d /home/"$USERNAME" -m -s /bin/bash -p $(echo "$PASSWORD" | openssl passwd -1 -stdin) "$USERNAME"
fi

echo -e "\n---------------------------------------------------------------------------------\n"

echo -e "What Software should the server run on?\n"
echo "[1] SPIGOT"
echo "[2] CRAFTBUKKIT"
echo "[3] PAPERSPIGOT"

echo ""

CASE=1
while [ $CASE -ne 0 ]; do
	read -r -p "Please enter the number of your choice: " TYPE_INT
	case $TYPE_INT in
		1)
		TYPE="spigot"
		CASE=0
		;;
		2)
		TYPE="craftbukkit"
		CASE=0
		;;
		3)
		TYPE="paperspigot"
		CASE=0
		;;
	esac
done

echo -e "Which Version would you like to use?\n"
echo "[1] 1.8.8"
echo "[2] 1.12.2"
echo "[3] LATEST"

echo ""

CASE=1
while [ $CASE -ne 0 ]; do
        read -r -p "Please enter the number of your choice: " VERSION_INT
        case $VERSION_INT in
                1)
                VERSION="1.8.8"
                CASE=0
                ;; 
                2)    
                VERSION="1.12.2"
                CASE=0
                ;;
                3)
                VERSION="latest"
                CASE=0
                ;;
        esac
done

rm -f /home/"$USERNAME"/*.jar
wget -q https://yivesmirror.com/files/spigot/"$TYPE"-"$VERSION".jar -O /home/"$USERNAME"/"$TYPE"-"$VERSION".jar

cat > /home/"$USERNAME"/start.sh << EOF
#!/bin/bash

screen -S minecraft java -jar $TYPE-$VERSION.jar nogui

EOF

chmod +x /home/"$USERNAME"/start.sh
chown -R "$USERNAME":"$USERNAME" /home/"$USERNAME"

echo -e "\n---------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------"
echo -e "---------------------------------------------------------------------------------\n"
echo "SETUP COMPLETED SUCCESSFULLY"

echo -e "\n---------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------"
echo -e "---------------------------------------------------------------------------------\n"

if [ ! -z "$PASSWORD" ]; then
	PASSWORD_SENTENCE="- Password: $PASSWORD"
fi
echo "Please connect via SSH (e.g. with Putty or another SSH client) using the following credentials:"
echo -e "\n---------------------------------------------------------------------------------\n"

echo "- Username: $USERNAME"
if [ ! -z "$PASSWORD_SENTENCE" ]; then
	echo $PASSWORD_SENTENCE
fi

echo -e "\n---------------------------------------------------------------------------------\n"