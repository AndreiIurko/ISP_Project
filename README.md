# ISP Project
This is a project that shows how you can build a small internet service provider (ISP) company. This implementation is based on virtual machines, assuming that the host machine is the entry point to the Internet exchange (IX). The implementation diagram is provided below:

![Scheme of the ISP](https://github.com/AndreiIurko/ISP_Project/blob/master/sources_for_readme/scheme.png)

## Setup
This project uses Qemu for virtualization and assumes that you are using a Linux host. Please also ensure that you have [Bird](https://bird.network.cz/) with version 2.0 or newer and Dnsmasq. To configure the host in ISP exit point mode, read and run the *setup.sh* program:
```
sudo ./setup.sh
```
This program will create all necessary bridges and tap interfaces.
The project supports several features:
 - NAT on users router for users segment
 - Traffic control with limited speed and total usage
 - DHCP on user router for users
 - IPv6 support
 - Simple DNS server on the host machine
 
 To enable these features the following scripts should be executed in user and companies routers:
 - *users_dir/users.sh* and *users_dir/users_tc.sh* in users router
 - *companies_dir/companies.sh* and *companies_dir/companies_tc.sh* in companies router
 
 To run these scripts in routers the following steps can be followed:
 - Log in as a root in the virtual machine. If you are using the image provided in the *setup.sh*, when use *osboxes.org* as a password.
 - Assign a unique IP and define the default route:
   ```
   ip a add 10.203.0.2/17 dev ens3
   ip ro add default via 10.203.0.1
   ```
   Where 10.203.0.1 is an address we assigned in setup.sh for communication with the host and ens3 is the interface on the router VM which connects the router to the private hub.
 - Make sure your host has an SSH server and copy the file to the router:
    ```
    scp username@10.10.10.203:/path/to/script .
    ```
    Where 10.10.10.203 is an address assigned to host machine wireless interface.

### VirtualBox
The same scheme can be created using VirtualBox. Instead of creating images and interfaces using commands in the *setup.sh* the following steps can be made:
 - Create images in VirtualBox
 - Connect the routers and host machine using host-only networking and routers with users/companies using internal networking. For more information refer to [VirtualBox documentation](https://www.virtualbox.org/manual/ch06.html).
 - Repeat the router setup with the scripts step.

### Internet connection
If you are peering with someone who can give internet access when this step is not necessary. However, most likely this will be used as a learning project and peering will be between the same ISPs. So, to enable the internet on VMs for the setup, the following commands can be run on the host:
```
iptables -t nat -A POSTROUTING -o wlp2s0 -j MASQUERADE
ip6tables -t nat -A POSTROUTING -o wlp2s0 -j MASQUERADE
```
Replace wlp2s0 with your internet access interface. This will masquerade all packets coming from our network with host IP, so all necessary packets can be installed on the VMs.

For any questions feel free to contact me by email: andreiiurko01@gmail.com













