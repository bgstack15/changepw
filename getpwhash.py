#!/bin/python
# Reference:
#    https://bgstack15.wordpress.com/2017/12/03/python-get-linux-compatible-password-hash/
import crypt, getpass, sys;
if len(sys.argv) >= 2: 
 thisraw=str(sys.argv[1]);
else:
 thisraw=getpass.getpass(prompt='New password: ')
print(crypt.crypt(thisraw,crypt.mksalt(crypt.METHOD_SHA512)))
