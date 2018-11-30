Running the multitool on Kubernetes using the POD network is as simple as:

```shell
$ kubectl run nwtool --image praqma/network-multitool
```

This allows you to use the utilities from the multitool to test on the POD
network, however, sometimes you want to do similar testing using the host
network.  This can be achieved by running the multitool using host
networking. The manifest file in this folder contain a daemonset definition that
will run an instance of the multitool on all hosts in the cluster using host
networking.

Obviously one could simply install the tools on the hosts, however, there are
several reasons why this is not ideal.

- We should keep the infrastructure immutable and not install anything on the
  hosts. Ideally we should never ssh to our cluster hosts.

- Its cumbersome to install the tools since they might be needed on several hosts

- Removing the tools and dependencies after use could be difficult

- Using the tools from a Kubernetes resource allows one to integrate with other
  resources like e.g. volumes for packet capture files.

Using the daemonset provides a 'cloud native' approach to provision
debugging/testing tools.