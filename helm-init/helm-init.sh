#!/bin/bash
## Deploys tiller in the tiller namespace with a role and rolebinding restricting it
## to modify only its own and the default namespace. TLS certificates are also provided
## to Tiller to secure tiller and helm connections.
cd "$(dirname "$0")"

#Make certificates and key for the root CA, tiller and for helm
./tls.make

#Install tiller
kubectl create namespace tiller
kubectl create serviceaccount tiller -n tiller
kubectl create -f role-tiller.yaml
helm init --service-account=tiller --tiller-namespace=tiller --tiller-tls \
    --tiller-tls-cert certs/tiller.crt \
    --tiller-tls-key certs/tiller.key \
    --tiller-tls-verify --tls-ca-cert certs/ca.crt

#Move the certs to helm home for convenience (these need to be generated for anyone using the cluster)
cp certs/ca.crt $(helm home)/ca.pem
mv certs/myclient.crt $(helm home)/cert.pem
mv certs/myclient.key $(helm home)/key.pem