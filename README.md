NodeJsDevBox
============
Vagrant/Puppet project facilitating preconfigured node.js development box. 

Adding VVV project to the branch
================================
To sync [VVV](https://github.com/Varying-Vagrant-Vagrants/VVV) project execute:
```
rsync  -avh --no-compress --progress --delete --dry-run --exclude-from 'exclude-list'  ../VVV/ .
```
