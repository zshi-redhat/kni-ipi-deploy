# kni-ipi-deploy
Files related to the deployment of ipi

DNS/DHCP Server
1. Create a "baremetal" bridge with IP 10.0.1.2 and make your baremetal network interface its slave
2. ifup baremetal
3. git clone https://github.com/redhat-nfvpe/kni-ipi-deploy.git
4. vi kni-ipi-deploy/settings.sh (set appropriate values for your environment)
5. cd kni-ipi-deploy/iptables
6. ./gen_iptables.sh
7. cd ../dns
8. ./start.sh
9. cd ../dhcp
10. ./start.sh
11. podman ps (to verify dnsmaq and coredns containers are running)

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
12. vi baremetal-prep.sh (add baremetal "no peer DNS")
13. ./baremetal-prep.sh -p < provisioning interface > -b < baremetal interface > -m
14. cd
15. cp ~/clusterconfigs/openshift/99-metal3-config.yaml ~/.
16. sudo ifdown baremetal
17. sudo ifup baremetal
18. git clone https://github.com/redhat-nfvpe/kni-ipi-deploy.git
19. vi kni-ipi-deploy/settings.sh (set appropriate values for your environment)

