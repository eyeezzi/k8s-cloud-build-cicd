if [ "$#" -ne 3 ]; then
	echo "Usage: ./gen-access <namespace> <service-account> <cluster>"
	echo "Output: <kubeconfig> <token>"
	exit 1
fi

ns=$1
sa=$2
cluster=$3
kubeconfig=$cluster.$ns.$sa.kubeconfig.yaml
tokenfile=$cluster.$ns.$sa.token

# get cluster auth credentials
server=`kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}'`
secret=`kubectl -n $ns get sa $sa -o jsonpath="{.secrets[0].name}"`
cert=`kubectl -n $ns get secret $secret -o jsonpath="{.data.ca\.crt}"`
token=`kubectl -n $ns get secret $secret -o jsonpath="{.data.token}" | base64 --decode`

# generate kubeconfig
kubectl --kubeconfig=$kubeconfig config view > $kubeconfig
file1=/tmp/`uuidgen` && \
    file2=/tmp/`uuidgen` && \
    echo $server > $file1 && \
    echo $cert | base64 --decode > $file2 && \
    kubectl --kubeconfig=$kubeconfig config set-cluster $cluster --server=`cat $file1` --certificate-authority=$file2 --embed-certs && \
	rm $file1 $file2
kubectl --kubeconfig=$kubeconfig config set-context $ns-$sa --cluster=$cluster --user=$sa --namespace=$ns
kubectl --kubeconfig=$kubeconfig config use-context $ns-$sa
kubectl --kubeconfig=$kubeconfig config set-credentials $sa --token=REDACTED

echo $token > $tokenfile

# verify generated kubeconfig and token can access cluster
res=`kubectl --kubeconfig=$kubeconfig --token=$token auth can-i create deployment -n $ns`
if [ "$res" == "yes" ]; then
	echo "VERIFIED"
else
	echo "UNKNOWN PROBLEM: It appears deployer does not have correct authorization."
fi