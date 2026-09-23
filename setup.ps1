$location = "northcentralus"
$group = "rg-aks-coredns-ncus"
$cluster = "akscoredns"

# create the resource group and two-node AKS cluster
az group create -n $group -l $location
az aks create -g $group -n $cluster -l $location `
	--node-count 2 `
	--network-plugin azure `
	--network-plugin-mode overlay `
	--pod-cidr 192.168.0.0/16 `
	--service-cidr 10.20.0.0/16 `
	--dns-service-ip 10.20.0.10 `
	--generate-ssh-keys

# connect kubectl to the cluster
az aks get-credentials -g $group -n $cluster --overwrite-existing

# deploy custom CoreDNS and the client workload
kubectl apply -f ".\custom-coredns.yaml"
kubectl apply -f ".\dns-client.yaml"
kubectl rollout status deployment/custom-coredns -n custom-dns
kubectl rollout status deployment/dns-client

# show requests resolved through custom CoreDNS
kubectl logs deployment/dns-client --tail=5
