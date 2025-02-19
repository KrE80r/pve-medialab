#!/usr/bin/env bash
# ----------------------------------------------------------------------------------
# Filename:     jackett_sw.sh
# Description:  Source script for App SW
# ----------------------------------------------------------------------------------

#---- Source -----------------------------------------------------------------------

DIR=$( cd "$( dirname "${BASH_SOURCE}" )" && pwd )

#---- Dependencies -----------------------------------------------------------------

# Run Bash Header
source $DIR/basic_bash_utility.sh

#---- Dependencies -----------------------------------------------------------------
#---- Static Variables -------------------------------------------------------------

# Update these variables as required for your specific instance
app="$REPO_PKG_NAME"       # App name
app_uid="$APP_USERNAME"        # App UID
app_guid="$APP_GRPNAME"        # App GUID

#---- Other Variables --------------------------------------------------------------
#---- Other Files ------------------------------------------------------------------
#---- Body -------------------------------------------------------------------------

#---- Prerequisites

# Create flexget dir
su - $app_uid "mkdir -m 775 -p /home/$app_uid/flexget"
# Create sample config file
cat <<EOF | tee /home/media/flexget/config.yml >/dev/null
tasks:
  test task:
    rss: http://mysite.com/myfeed.rss
    series:
      - My Favorite Show
      - Another Good Show:
          quality: 720p
    download: /home/me/watchdir/
EOF
chown "$app_uid":"$app_guid" /home/media/flexget/config.yml

# Install python3
apt-get install python3.9-venv -y 2> /dev/null
python3 -m venv ~/flexget/

# Upgrade virtualenv tools
~/flexget/bin/pip install --upgrade pip setuptools

# Install Flexget
~/flexget/bin/pip install flexget

# Run Flexget
source ~/flexget/bin/activate


#---- Installing Flexget
msg "Installing ${CT_HOSTNAME_VAR^} software (be patient, might take a while)..."
pct exec $CTID -- bash -c 'cd ~/flexget/; bin/pip install flexget'
pct exec $CTID -- bash -c 'source ~/flexget/bin/activate'




# Install required SW
sudo apt-get -y install python-urllib3 python3-openssl libcurl4-openssl-dev bzip2 subversion 2>/dev/null
sudo apt-get -y install curl 2>/dev/null
apt-get install -y apt-transport-https gnupg 2>/dev/null

#---- Install Jackett

# Set args
filename="Jackett.Binaries.LinuxAMDx64.tar.gz" # Jacket tar file name
release=$(wget -q https://github.com/Jackett/Jackett/releases/latest -O - | grep "title>Release" | cut -d " " -f 4)
# Download files
sudo wget -Nc https://github.com/Jackett/Jackett/releases/download/$release/"$filename" -P /tmp
# Extract files
sudo tar -xzf "/tmp/$filename" -C /opt
rm "/tmp/$filename"

# Create Jackett home folders
mkdir -m 775 -p /home/media/.config/Jackett/Indexers
chown -R "$app_uid":"$app_guid" /home/media/.config

# Create Jackett Service file
cat << EOF > /etc/systemd/system/jackett.service
[Unit]
Description=Jackett Daemon
After=network.target

[Service]
SyslogIdentifier=jackett
Restart=always
RestartSec=5
Type=simple
User=media
Group=medialab
Environment=XDG_CONFIG_HOME=/home/media/.config
WorkingDirectory=/opt/Jackett
ExecStart=/opt/Jackett/jackett --NoRestart
TimeoutStopSec=20

[Install]
WantedBy=multi-user.target
EOF

# Start Jackett service (create startup system jackett files)
sudo systemctl enable "jackett.service"
pct_start_systemctl "jackett.service"
sleep 3

#---- Create App backup folder on NAS
if [ -d "/mnt/backup" ]
then
 su - $app_uid -c "mkdir -p /mnt/backup/$REPO_PKG_NAME"
fi
#-----------------------------------------------------------------------------------