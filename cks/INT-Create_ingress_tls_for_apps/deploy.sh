#!/bin/bash
set -e

SSH_OPTIONS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"

echo "🔧 Creating lab resources ..."

# Ajoute l'entrée localement
echo "127.0.0.1 www.my-web-site.org" | sudo tee -a /etc/hosts > /dev/null

# Ajoute l'entrée sur les nœuds workers
for node in $(kubectl get nodes --no-headers | grep -v "control-plane" | awk '{print $1}'); do
  ssh $SSH_OPTIONS vagrant@$node bash -s <<'EOSSH'
    echo "127.0.0.1 www.my-web-site.org" | sudo tee -a /etc/hosts > /dev/null
EOSSH
done

kubectl apply -f manifests/ > /dev/null
bash tools/install-ingress-nginx.sh > /dev/null

echo
echo "************************************"
echo
cat README.txt
echo



# #!/bin/bash
# set -e

# SSH_OPTIONS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"

# echo "🔧 Creating lab resources ..."

# cat <<EOF | sudo tee -a /etc/hosts > /dev/null
# 127.0.0.1 www.my-web-site.org
# EOF

# for node in $(kubectl get nodes --no-headers | grep -v "control-plane" | awk '{print $1}'); do
#   ssh $SSH_OPTIONS vagrant@$node bash <<'EOF'
#     cat <<EOF2 | sudo tee -a /etc/hosts > /dev/null
# 127.0.0.1 www.my-web-site.org
# EOF2 
# EOF
# done

# kubectl apply -f manifests/ > /dev/null
# bash tools/install-ingress-nginx.sh

# echo
# echo "************************************"
# echo
# cat README.txt
# echo