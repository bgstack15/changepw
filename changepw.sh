#!/bin/sh
# File: changepw.sh
# Location: /etc/ansible/shell/changepw/
# Author: bgstack15@gmail.com
# Startdate: 2018-01-04
# Title: Script that Executes the Password Change Across Listed Systems
# Purpose: Sets new password for local user across all systems in inventory, grouped by site
# History:
# Usage:
#    Call prep.sh first, then changepw.sh
# Reference:
# Improve:
# Dependencies:
#    vcenter_matrix/generate.sh
# Documentation:
#    Run from the ansible control host, as an account that can ssh in and root up.
#    This will hardcore modify the /etc/shadow file, which will trigger AIDE.

# FUNCTION
clean_changepw() {
   rm -rf "${tmpdir}" 1>/dev/null 2>&1
}

# TEMP FILES
tmpdir="$( mktemp -d )"
trap 'clean_changepw ; trap "" 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 ; exit 0 ;' 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20
vaultfile="$( TMPDIR="${tmpdir}" mktemp )"
pwfile="$( TMPDIR="${tmpdir}" mktemp )"

# GET USER-PROVIDED VALUES
tl="${1}" # this limit of hosts in the inventory
test -z "${tl}" && tl="all"
tu=bgstack15
printf "%s" 'New password: '
read -s pw1
printf '\n'
printf "%s" 'New password (again): '
read -s pw2
printf '\n'

# DEFINE VALUES
td=/etc/ansible/shell/changepw
playbook="${td}/changepw.yml"
inv="${td}/inventory-changepw.yml"
logfile="${td}/log/changepw.$( date "+%Y-%m-%d-%H%M%S" ).log"
py_getpwhash="${td}/getpwhash.py"

# VALIDATE VALUES
if test "${pw1}" != "${pw2}";
then
   echo "${0}: Passwords do not match. Aborted."
   exit 1
fi
pwhash="$( /bin/python "${py_getpwhash}" "${pw1}" )"
if ! mkdir -p "$( dirname "${logfile}" )" ; then echo "${0}: Need write access to directory of logfile \"${logfile}\". Aborted." 1>&2 && exit 1 ; fi
if ! touch "${logfile}" ; then echo "${0}: Need write access to logfile \"${logfile}\". Aborted." 1>&2 && exit 1 ; fi

# PREPARE VAULT FILE
echo -e "thispassword: ${pw1}" > "${vaultfile}"
echo -e "thispasswordhash: ${pwhash}" > "${vaultfile}"
echo "thisuser: ${tu}" >> "${vaultfile}"
echo "$( pwmake 300 )" > "${pwfile}"
ansible-vault encrypt "${vaultfile}" --vault-password-file "${pwfile}" 2>&1 | grep -viE 'encryption successful'
unset pw1 pw2

# MAIN LOOP
{
   echo "limit=${tl}"
   for ts in preprod prod ; # thissite
   do
      echo "---------- ${ts}" | tr '[[:lower:]]' '[[:upper:]]'
      # for maintenance: --skip-tags 'expect,changepw'

      # USE ONE OF THE TWO FOLLOWING PLAYBOOK STATEMENTS

         ## Use the password hash, so we do not have to use the pexpect package
         time unbuffer ansible-playbook "${td}/changepw.yml" -i "${inv}" --become -u ansible_${ts} -l "${tl}" --vault-password-file "${pwfile}" -e "vaultfile=${vaultfile}" -e "sitelimit=${ts}" -v --skip-tags 'expect'

         ## Use pexpect, which requires the yum package
         #time unbuffer ansible-playbook "${td}/changepw.yml" -i "${inv}" --become -u ansible_${ts} -l "${tl}" --vault-password-file "${pwfile}" -e "vaultfile=${vaultfile}" -e "sitelimit=${ts}" -v --skip-tags 'hardcore'

   done
} 2>&1 | tee -a "${logfile}"

# EXIT CLEANLY
exit 0
