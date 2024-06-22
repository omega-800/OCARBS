#!/bin/sh

echo "CPU_MAX_PERF_ON_BAT=40
CPU_SCALING_GOVERNOR_ON_BAT=powersave
CPU_ENERGY_PERF_POLICY_ON_BAT=power
CPU_BOOST_ON_BAT=0
CPU_HWP_DYN_BOOST_ON_BAT=0
START_CHARGE_THRESH_BAT0=40
STOP_CHARGE_THRESH_BAT0=90
PLATFORM_PROFILE_ON_BAT=low-power
WIFI_PWR_ON_BAT=on
WOL_DISABLE=N
PCIE_ASPM_ON_BAT=powersave
CPU_MIN_PERF_ON_BAT=0
RUNTIME_PM_ON_BAT=auto
CPU_SCALING_GOVERNOR_ON_AC=performance
CPU_ENERGY_PERF_POLICY_ON_AC=performance
CPU_MIN_PERF_ON_AC=0
CPU_MAX_PERF_ON_AC=100
CPU_BOOST_ON_AC=1
CPU_HWP_DYN_BOOST_ON_BAT=1
PLATFORM_PROFILE_ON_AC=performance
" > /etc/tlp.conf

echo "
ChallengeResponseAuthentication no
AllowSFTP no
LogLevel VERBOSE
MaxSessions 2
Port 51423 
TCPKeepAlive no
PasswordAuthentication no
PermitRootLogin no
PermitEmptyPasswords no
PermitUserEnvironment no
UseDNS no
StrictModes yes
IgnoreRhosts yes
RhostsAuthentication no
RhostsRSAAuthentication no
ClientAliveInterval 300
ClientAliveCountMax 0
MaxAuthTries 3
AllowTcpForwarding no
X11Forwarding no
AllowAgentForwarding no
AllowStreamLocalForwarding no
AuthenticationMethods publickey
HostbasedAuthentication no
KexAlgorithms diffie-hellman-group-exchange-sha256
MACs hmac-sha2-512,hmac-sha2-256
Ciphers aes256-ctr,aes192-ctr,aes128-ctr
HostKeyAlgorithms ssh-ed25519,rsa-sha2-512,rsa-sha2-256
" > /etc/ssh/sshd_config

echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINBVYpXJvGwWCWy+sv+LQAERdI9pUfC+iTIag1gsQgx2 omega@archie" > "/home/$1/.ssh/authorized_keys"

ufw default deny
ufw limit ssh
ufw allow 51423
ufw enable

#TODO: wg && forti configs
