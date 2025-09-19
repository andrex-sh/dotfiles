systemctl list-unit-files --state=enabled --no-legend | awk '{print $1}' > sys_units.txt
systemctl --user list-unit-files --state=enabled --no-legend | awk '{print $1}' > user_units.txt
