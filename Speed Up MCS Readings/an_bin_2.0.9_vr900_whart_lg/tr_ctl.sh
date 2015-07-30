#! /bin/sh

if [ ! "$1" = "restart" ]; then
	echo "Usage: $0 restart pwr_id  \n where pwr_id is 1 or 2\n"
	exit 1	
fi

if [ "$2" -eq 1 ]; then
	devmem 0xF0000810 32 0x00000000
	sleep 2
	devmem 0xF0000810 32 0x00000024
else if [ "$2" -eq 2 ]; then

	devmem 0xF0000820 32 0x00000000
	sleep 2
	devmem 0xF0000820 32 0x00000024
else 
	echo "invalid second parameter -> should be 1 or 2 "
	exit 1	
fi
fi

