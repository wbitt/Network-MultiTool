Running the multitool on Kubernetes using the POD network is as simple as:

```shell
kubectl run nwtool --image wbitt/network-multitool
```

This allows you to use the utilities from the multitool to test on the POD
network, however, sometimes you want to do similar testing using the host
network. This can be done with the DaemonSet in
`kubernetes/multitool-daemonset.yaml`. It runs one instance of the multitool on
every node, using host networking.

```shell
kubectl apply -f kubernetes/multitool-daemonset.yaml
```

The manifest pins the image to a release tag. Change that tag deliberately,
after you have tested the new release.

The DaemonSet listens on `1180` and `11443`, so it does not fight with a web
server that already uses `80` and `443` on the node. It runs as root, because
packet capture needs it, and it adds `NET_ADMIN` and `NET_RAW`. The memory
limit is `256Mi`, which is enough for `tcpdump`, `nmap`, and `tshark` in normal
use. Raise it if you capture large files.

Readiness, liveness, and startup probes check the page on port `1180`.

Obviously one could simply install the tools on the hosts, however, there are
several reasons why this is not ideal.

- We should keep the infrastructure immutable and not install anything on the
  hosts. Ideally we should never ssh to our cluster hosts.

- It's cumbersome to install the tools since they might be needed on several hosts

- Removing the tools and dependencies after use could be difficult

- Using the tools from a Kubernetes resource allows one to integrate with other
  resources like e.g. volumes for packet capture files.

Using the daemonset provides a 'cloud native' approach to provision
debugging/testing tools.
