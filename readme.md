# Custom CoreDNS on AKS

This example deploys a separate CoreDNS service on Azure Kubernetes Service (AKS). Workloads can opt in to this DNS service without changing the AKS-managed CoreDNS configuration.

The custom CoreDNS deployment:

- Runs two replicas in the `custom-dns` namespace.
- Allows no more than one replica per node through required pod anti-affinity.
- Exposes DNS over UDP and TCP at the fixed service IP `10.20.0.53`.
- Forwards queries to Google Public DNS at `8.8.8.8`.
- Caches responses for 30 seconds and enables cache prefetching.

The sample client opts in with this pod configuration:

```yaml
dnsPolicy: None
dnsConfig:
  nameservers:
    - 10.20.0.53
```

It then queries the A record for `www.microsoft.com` five times per second and logs the DNS responses.

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

A successful client log includes resolved addresses similar to:

```text
Address: 23.35.30.73
```

To inspect the custom CoreDNS query logs, run:

```powershell
kubectl logs -n custom-dns -l app=custom-coredns --prefix --tail=20
```

## Inspect cache metrics

CoreDNS exposes cache hits and prefetch activity as Prometheus metrics on port `9153`.

In one PowerShell terminal, forward the metrics port from one CoreDNS replica:

```powershell
kubectl port-forward -n custom-dns deployment/custom-coredns 9153:9153
```

In another PowerShell terminal, display the cache request, hit, and prefetch counters:

```powershell
((Invoke-WebRequest http://localhost:9153/metrics).Content -split "`n") | Where-Object { $_ -match '^coredns_cache_(requests|hits|prefetch)_total' }
```

Cache misses can be calculated by subtracting `coredns_cache_hits_total` from `coredns_cache_requests_total`. An increase in `coredns_cache_prefetch_total` confirms that prefetching occurred. Because port forwarding targets one replica, repeat the inspection for the other CoreDNS Pod when checking totals across the deployment.
