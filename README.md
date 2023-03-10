# infra
## Bootstrap home office IT infrastructure

> This repository has emerged as a collection of automatization scripts for stereotypical home office administrative tasks.
> These include: 
> - getting ready for use remote VDS in literally minutes with all the complex setup I need (the _initVDS_ project) 
> - getting ready for use home office network gateway (the _initPI_ project.). I usually use SBCs for this purpose, which is why there is *PI* in the name of the project.
> - getting ready for use personal laptop/workstation quick (not here, yet)

**These scripts were written and tested for Debian.**

As a developer who works from home, I face necessity of maintaining my own safe home office IT infrastructure. This includes secure WiFi (EAP-TTLS based on FreeRADIUS), secure DNS (DNS-over-TLS with Unbound, as a forwarder), custom firewall (netfilter) rules, and maybe a couple of other things. 
I still cannot find enough time to bring all scripts into one. This is the reason, why there are _initVDS_ and _initPI_ instead of just _init_ project who would accept a parameter. Nevertheless, the *initVDS* has been tested and proven to be able to provide me a production-ready VDS, as a part of my home office IT infrastructure, in literally minutes. The *initPI* is still work in progress, which means that I had to manually modify the script while on the device to make it run further, or even delete some part of the script and do some part of work manually. Nevertheless, I find all these scripts in both repositories useful and time-saving.

