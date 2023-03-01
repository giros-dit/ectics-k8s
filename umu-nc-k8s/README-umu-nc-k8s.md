Acceso al cluster de Kubernetes del nodo central
------------------------------------------------

- Direcciones nodos:

k8s-nc2: 10.20.240.51 --> control+worker
k8s-nc3: 10.20.240.52 --> worker
k8s-nc4: 10.20.240.53 --> worker

- Acceso a nodos del cluster desde nodocentral1:

ssh -i k8s/keys/k8s-nc.pem root@10.20.240.5{1|2|3}

- Ejecución de comandos en el cluster:

  + Desde k8s-nc2:

ssh -i k8s/keys/k8s-nc.pem root@10.20.240.51
kubectl get nodes

  + Desde nodocentral1:

kubectl --kubeconfig k8s/k8s-config-nc get nodes
kubect-nc get nodes   # kubectl-nc es un alias definido en .bashrc
                      # de la cuenta smartmurcia

- Para ver continuamente los pod, servicios y deployments:

while true; do clear; kubectl-nc get all; sleep 5; done

- Ejemplos de despliegue:

  1 - Despliegue de un servidor nginx con tres replicas desde la línea de comandos:

kubectl-nc create deployment nginx-app --image=nginx --replicas=3


Convertir master en worker:

kubectl taint nodes k8s-nc2 node-role.kubernetes.io/control-plane-


Receta https://www.server-world.info/en/note?os=Ubuntu_20.04&p=openstack_yoga&f=6

- Bajamos la imagen:
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img

- Modificamos la imagen (opcional):
sudo modprobe nbd
sudo qemu-nbd --connect=/dev/nbd0 jammy-server-cloudimg-amd64.img
sudo mount /dev/nbd0p1 /mnt

...modificaciones...
# Allow root login
sudo sed -i 's/disable_root:.*/disable_root: false/' /mnt/etc/cloud/cloud.cfg
# Allow ssh with user/passwd
sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config

sudo umount /mnt
sudo qemu-nbd --disconnect /dev/nbd0p1

- Subimos la imagen a OpenStack
source bin/admin-openrc-central.sh
openstack image create "jammy-server-cloudimg-amd64" --file jammy-server-cloudimg-amd64.img --disk-format qcow2 --container-format bare --public


Creacion de una imagen partiendo de una máquina virtual

- Arrancar la maquina virtual e instalar o modificar lo deseado

- Antes de parar la maquina, rehabilitar cloud-init y permitir ssh con user/passwd:
sudo rm -rf /var/lib/cloud/*
sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
passwd ubuntu

- Reconfigurar netplan
network:
    version: 2
    ethernets:
        ens3:
            dhcp4: true

- Paramos la maquina virtual:
openstack server stop k8s-img

- Creamos la imagen partiendo de la maquina virtual:
openstack server image create --name jammy-server-cloudimg-amd64-k8s --wait k8s-img

Nota: el parametro --name parece que no funciona (?). Tampoco funciona el comando para cambiar el nombre desde la linea de comandos:
    openstack image set k8s-img --name jammy-server-cloudimg-amd64-k8s
Hay que poner el nombre a mano desde el dashboard.

- Salvamos la imagen a fichero:
openstack image save --file jammy-server-cloudimg-amd64-k8s.img jammy-server-cloudimg-amd64-k8s


openstack image create --disk-format qcow2 --container-format bare --public --file  ubuntu_22_04_base.qcow2 ubuntu_22_04_base


Cloud-init:

curl http://169.254.169.254/openstack/latest
curl http://169.254.169.254/openstack/latest/meta_data.json
curl http://169.254.169.254/openstack/latest/user_data
curl http://169.254.169.254/openstack/latest/meta_data.json | python -m json.tool

dpkg-reconfigure cloud-init permite elegir el origen de la información usada para la autoconfiguración

cloud-init status, permite ver el estado del demoniot de cloud-init (si ha terminado o no, etc). Con --wait se puede esperar a que termine.

Para validar un fichero cloud-init:

cloud-init schema --config-file k8s-nc2.cfg


kubectl-nc expose deployment nginx-app --type=NodePort --port=80

# Cambiamos la pagina inicial (index.html) de los servidores por el hostname
# para diferenciarlas
for pod in $(kubectl-nc get pod --output=jsonpath={.items..metadata.name}); do kubectl-nc exec -ti $pod -- bash -c "echo \$(hostname) > /usr/share/nginx/html/index.html"; done

      - Comprobación de funcionamiento:

PORT=$(kubectl-nc get service/nginx-app --output jsonpath='{.spec.ports[].nodePort}')
curl 10.20.240.51:$PORT
curl 10.20.240.52:$PORT
curl 10.20.240.53:$PORT

Con un bucle se aprecia el balanceo de tráfico entre las tres replicas:
while true; do curl 10.20.240.51:$PORT; sleep 1; done

      - Borrado del escenario:
kubectl-nc delete deployment.apps/nginx-app
kubectl-nc delete service/nginx-app

  2 - Despliegue de un servidor nginx con tres replicas desde ficheros yaml

cd ~/k8s/examples
kubectl-nc apply -f nginx-web-server.yaml
kubectl-nc apply -f nginx-service.yaml

      - Comprobación de funcionamiento:

curl 10.20.240.51:30000
curl 10.20.240.52:30000
curl 10.20.240.53:30000

      - Borrado del despliegue:

kubectl-nc delete deployment.apps/nginx-web-server-pool
kubectl-nc delete service/nginx-service
