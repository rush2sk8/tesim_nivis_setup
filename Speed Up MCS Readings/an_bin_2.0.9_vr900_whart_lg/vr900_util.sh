#! /bin/sh


vr900_tr_init()
{
	#Added for testing RESET ISSUE
	devmem 0xF0000A48 16 0x030F
	devmem 0xF0000A09 8 0x00
	devmem 0xF0000A19 8 0x1F
	
	# Power on the acquisition board radios
	
	devmem 0xF0000810 32 0x00000000
	sleep 1
	devmem 0xF0000810 32 0x00000024
	
	
	
	# Dan Cornescu Recomendations (what do they do?)
	#devmem 0xF0000A48 16 0x030F
	devmem 0xF0000A19 8 0x00
	devmem 0xF0000A09 8 0x1F
}