# kni-ipi-deploy
Files related to the deployment of ipi

The steps below are currently written for an environment where you have a DNS/DHCP server, a provisioning server and then 3 master and 3 worker nodes for the actual cluster.  If you use a different setup than this, further customization is required than is described below.  NOTE: we are currently working on further parameterizing this repo so that it supports a wider variety of baremetal environments.

DNS/DHCP Server
1. SSH to server as root
2. Create a "baremetal" bridge with IP 10.0.1.2/24 and make your baremetal network interface its slave
3. ifup baremetal
4. git clone https://github.com/redhat-nfvpe/kni-ipi-deploy.git
5. cd kni-ipi-deploy
6. vi settings.sh (set appropriate values for your environment)
7. cd iptables
8. ./gen_iptables.sh
9. cd ../dns
10. ./start.sh
11. cd ../dhcp
12. ./start.sh
13. podman ps (to verify dnsmaq and coredns containers are running)

Provisioning Host
1. Install RHEL 8.1 on provisioning host
2. SSH to provisioning host as root
3. Register the system with subscription-manager and attach to appropriate pool
4. Create non-root user and give it password-less sudo
5. su - < non-root user >
6. Create your install-config.yaml with appropriate values for your environment
7. Copy your install-config.yaml to your home dir
8. mkdir -p ~/clusterconfigs/openshift
9. sudo yum install -y jq
10. git clone https://github.com/openshift-kni/baremetal-deploy.git
11. cd openshift-kni/baremetal-prep
12. vi baremetal-prep.sh (add baremetal "no peer DNS" -- sudo nmcli con mod baremetal ipv4.ignore-auto-dns yes)
13. ./baremetal-prep.sh -p < provisioning interface > -b < baremetal interface > -m
14. cd
15. cp ~/clusterconfigs/openshift/99-metal3-config.yaml ~/.
16. sudo ifdown baremetal
17. sudo ifup baremetal
18. Make sure your /etc/resolv.conf points to your DNS/DHCP server
19. Download your pull secret from https://cloud.redhat.com/openshift/install/metal/user-provisioned and place it in your home dir as "pull-secret.json"
20. git clone https://github.com/redhat-nfvpe/kni-ipi-deploy.git
21. cd kni-ipi-deploy
22. vi settings.sh (set appropriate values for your environment)
23. cd hacks
24. Rename the 99-ifcfg-eno2-\*.yaml and 99-ifcfg-ens1f0-\*.yaml files to match your provisioning and baremetal interfaces, respectively.  You will also need to decode the base64 string inside these files, change the device name, re-encode the data and then replace the base64 string inside the files.
25. cd ../install
26. ./preinstall.sh
27. ./install.sh

The installer may time-out at various stages of the deployment.  If this happens, you probably need to run clean.sh and re-deploy again with install.sh.  However, if you get a timeout in the final stage of the installer ("DEBUG Still waiting for the cluster to initialize: Working towards 4.3.0-0.nightly-2020-01-16-031402: XX% complete"), you might still succeed.  Monitor the "oc get nodes" and "oc get co" output (and you can also SSH into nodes to examine journalctl and/or crictl containers).  You may also find that CSRs get stuck in the pending state (seen via "oc get csr").  Our advice is to manually approve any CSR in the pending state.
