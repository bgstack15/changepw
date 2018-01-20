#!/bin/sh
# File: prep.sh
# Location: /etc/ansible/shell/changepw/
# Author: bgstack15@gmail.com
# Startdate: 2018-01-04
# Title: Script that Prepares the Inventory List for Changepw
# Purpose: Trims out the hosts that are not suitable for the password change, or unreachable
# History:
# Usage:
#    Run this before the changepw.sh script.
# Reference:
# Improve:
# Documentation:
# Dependencies:
#    vcenter_matrix

td=/etc/ansible/shell/changepw/
tf="${td}/inventory-changepw.yml"
tfailed="${td}/log/unreachable.$( date "+%Y-%m-%d" ).log"
vcenter_matrix_file=/etc/ansible/shell/vcenter_matrix/vcenter_matrix.csv

# DEPENDENCIES
if ! touch "${tf}" ; then echo "${0}: Need write access to file \"${tf}\". Aborted." 1>&2 && exit 1 ; fi 
chmod 0660 "${tf}"; 
if ! test -r "${vcenter_matrix_file}" ; then echo "${0}: Ensure vcenter list file \"${vcenter_matrix_file}\" is readable. Aborted." 1>&2 && exit 1 ; fi
if ! touch "${tfailed}" ; then echo "${0}: Need write access to file \"${tfailed}\". Aborted." 1>&2 && exit 1; fi

# FETCH ALL VIRTUAL MACHINES
thisinput="$( cut -d',' -f2 "${vcenter_matrix_file}" | sed -r -e 's/\.prod1\.example\.com//;' | sort )"
{
   echo "[prod]"
   echo "${thisinput}" | grep -E '1[0-9]{2}$'
   echo ""
   echo "[preprod]"
   echo "${thisinput}" | grep -E '2[0-9]{2}$'

} > "${td}/inventory-changepw.yml"

# REMOVE UNREACHABLE ONES
cat /dev/null > "${tfailed}"
ansible -i "${tf}" prod -u ansible_prod -m ping | grep -E '=>' | awk '!/SUCCESS/{print $1}' >> "${tfailed}"
ansible -i "${tf}" preprod -u ansible_preprod -m ping | grep -E '=>' | awk '!/SUCCESS/{print $1}' >> "${tfailed}"
grep -vE -f "${tfailed}" "${tf}" > "${tf}.$$"
/bin/mv "${tf}.$$" "${tf}"
