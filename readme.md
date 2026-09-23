# Custom CoreDNS on AKS

This example deploys a separate CoreDNS service on Azure Kubernetes Service (AKS). Workloads can opt in to this DNS service without changing the AKS-managed CoreDNS configuration.

The custom CoreDNS deployment:

- Runs two replicas in the `custom-dns` namespace.
- Allows no more than one replica per node through required pod anti-affinity.
- Exposes DNS over UDP and TCP at the fixed service IP `10.20.0.53`.
- Forwards queries to Google Public DNS at `8.8.8.8`.
- Caches responses for 5 seconds and enables cache prefetching.

The sample client opts in with this pod configuration:

```yaml
dnsPolicy: None
dnsConfig:
  nameservers:
    - 10.20.0.53
```

It then requests `https://www.microsoft.com/` every 5 seconds and logs the resolved IP address and HTTP status code.

## Files

- `setup.ps1` creates the resource group and two-node AKS cluster, connects `kubectl`, deploys the manifests, and displays client logs.
- `custom-coredns.yaml` defines the namespace, CoreDNS configuration, deployment, and service.
- `dns-client.yaml` defines the sample workload that uses the custom nameserver.

## Run

From the repository directory, run:

```powershell
.\setup.ps1
```

The script creates the `akscoredns` cluster in `northcentralus` under the `rg-aks-coredns-ncus` resource group. It configures the cluster with service CIDR `10.20.0.0/16`, which contains both the AKS DNS service at `10.20.0.10` and the custom CoreDNS service at `10.20.0.53`.

A successful client log resembles:

```text
resolved=23.35.30.73 status=200
```

To inspect the custom CoreDNS query logs, run:

```powershell
kubectl logs -n custom-dns -l app=custom-coredns --prefix --tail=20
```
