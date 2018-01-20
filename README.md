# Changepw
*Shell script that uses and aids ansible*
Use changepw to change a local user password on a set of hosts.

These scripts work together and must be run in order.

**prep.sh** makes a custom inventory file with all the hosts from the vcenter_matrix.csv list that can be ansible-pinged. If a system is unavailable for any reason, it will be excluded.
This script is not strictly necessary, but if you omit it you need to prepare the inventory-changepw.yml inventory file.

**changepw.sh** has a hardcoded username in it but prompts for the new password and its confirmation. It saves those values to a vault file and then loops through the hard-coded sites and runs the ansible playbook that changes the local user password.

### Usage

    cd /etc/ansible/shell/changepw
    ./prep.sh
    ./generate.sh
    
### Dependencies
This tool depends on the output of the vcenter_matrix tool, so run it first.

# Reference
## Weblinks
1. https://bgstack15.wordpress.com/2017/12/03/python-get-linux-compatible-password-hash/
