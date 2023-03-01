## Procedimiento de instalación del cluster K8s en el nodo central
### Creación de la imagen base
El primer paso a realizar para la instalación del cluster K8s es la creación de la imagen base que utilizarán los nodos del cluster (*jammy-server-cloudimg-amd64-k8s*), partiendo de una imagen genérica de Linux Ubuntu 22.04 ([*jammy-server-cloudimg-amd64*](https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img)). 
Para ello se han creado dos scripts: 
- *create-k8s-image.sh*, que crea una nueva máquina virtual en OpenStack partiendo de la imagen genérica,
- *install-k8s-nc-from-jammy-k8s*, que posteriormente instala en la máquina todos los paquetes software necesarios para el funcionamiento de K8s. 
```bash
source bin/admin-openrc-central.sh            # Carga de credenciales de OpenStack
mkdir -p keys
openstack keypair create k8s-nc > keys/k8s-nc # Creación de la pareja de claves
bin/create-k8s-image.sh                         # Creación de la máquina virtual 
ssh -i keys/k8s-nc.pem root@10.20.240.50      # Comprobación del acceso por ssh
bin/install-k8s-nc-from-jammy-k8s               # Instalación del software de k8s
```
Una vez instalado el software y antes de convertir la máquina virtual en una imagen, es necesario realizar algunas modificaciones manualmente:
- Reactivar el funcionamiento de cloud-init, borrando los ficheros que indican que ya se ha ejecutado:
```bash
sudo rm -rf /var/lib/cloud/*
```
- Modificar el fichero /etc/netplan/50-cloud-init.yam:
```bash
network:
    version: 2
    ethernets:
        ens3:
            dhcp4: true
```
- Modificar el servicio de SSH para permitir el acceso con claves de usuario:
```bash
sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' \ /etc/ssh/sshd_config
```
- Crear una cuenta para administración del cluster, por ejemplo, k8s:
```bash
adduser k8s
usermod -aG sudo k8s
```
Finalmente, se debe parar la máquina virtual y convertirla en imagen de OpenStack:
```bash
openstack server stop k8s-img
openstack server image create --name jammy-server-cloudimg-amd64-k8s --wait k8s-img
```
Nota: el parámetro --name no funciona correctamente y la imagen se crea con otro nombre distinto. Es necesario acceder al Dashboard de OpenStack y cambiar el nombre a mano a jammy-server-cloudimg-amd64-k8s.
La imagen creada se puede salvar a un fichero mediante el siguiente comando:
```bash
openstack image save --file jammy-server-cloudimg-amd64-k8s.img jammy-server-cloudimg-amd64-k8s
```

### Creación y configuración de las máquinas virtuales del cluster k8s
Una vez generada la imagen, se crean los nodos del cluster (k8s-nc2, k8s-nc3 y k8s-nc4) como máquinas virtuales en OpenStack utilizando el script:
```bash
bin/create-k8s-nc-from-jammy-k8s.sh
```
Cada nodo del cluster se despliega en su nodo de OpenStack correspondiente. A continuación, se configuran los nodos utilizando el script:
```bash
bin/ install-k8s-nc-from-jammy-k8s
```
Terminado este paso, el cluster está listo para usarse. 

La gestión del cluster se realiza mediante el comando kubectl estándar de K8s. Para poder acceder al cluster es necesario descargar primero el fichero con sus credenciales al sistema desde el que se vaya a ejecutar el comando kubectl. Dicho fichero está localizado en el nodo de control en el ordenador desde. Por ejemplo, se puede usar el comando:
```bash
scp -i k8s/keys/k8s-nc.pem root@10.20.240.51:.kube/config ~/.kube
```
Una vez copiado el fichero, se podrán ejecutar desde ese sistema todos los comandos kubectl. Por ejemplo, para comprobar la disponibilidad de los nodos del cluster:
```bash
kubectl get nodes
NAME      STATUS          ROLES           AGE   VERSION
k8s-nc2   Ready           control-plane   16d   v1.26.0
k8s-nc3   Ready           <none>          16d   v1.26.0
k8s-nc4   Ready           <none>          16d   v1.26.0
```
El acceso al cluster se realiza a través de la VLAN de servicios comunes (VLAN 3240). Las direcciones IP de los tres nodos están accesibles desde esa red:
- **k8s-nc2**: 10.20.240.51 --> control+worker
- **k8s-nc3**: 10.20.240.52 --> worker
- **k8s-nc4**: 10.20.240.53 --> worker

Adicionalmente, para instalar el proxy inverso Ingress-NGINX y el balanceador MetalLB se deben ejecutar los siguientes pasos:
```bash
wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.5.1/deploy/static/provider/baremetal/deploy.yaml
sed -i 's/NodePort/LoadBalancer/' deploy.yaml
kubectl apply -f deploy.yaml
```
Para comprobar que la instalación ha sido correcta, se puede utilizar el comando:
```bash
kubectl get pods -n ingress-nginx
```
Finalmente, para instalar el balanceador MetalLB, se deben ejecutar los comandos siguientes:
```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.7/config/manifests/metallb-native.yaml
kubectl apply -f conf/config-pool.yaml
kubectl apply -f conf/config-l2adv.yaml
```
Para comprobar que la instalación ha sido correcta, se puede utilizar el comando:
```bash
kubectl get all -n metallb-system
```
### Ejemplos de despliegue de servicio
1 - Despliegue de un servidor nginx con tres replicas desde la línea de comandos:
```bash
kubectl create deployment nginx-app --image=nginx --replicas=3
kubectl expose deployment nginx-app --type=NodePort --port=80
```
- Cambiamos la pagina inicial (index.html) de los servidores por el hostname para diferenciarlos:
```bash
for pod in $(kubectl get pod --output=jsonpath={.items..metadata.name}); do kubectl-nc exec -ti $pod -- bash -c "echo \$(hostname) > /usr/share/nginx/html/index.html"; done
```
- Comprobación de funcionamiento:
```bash
PORT=$(kubectl get service/nginx-app --output jsonpath='{.spec.ports[].nodePort}')
curl 10.20.240.51:$PORT
curl 10.20.240.52:$PORT
curl 10.20.240.53:$PORT
```
- Con un bucle se aprecia el balanceo de tráfico entre las tres replicas:
```bash
while true; do curl 10.20.240.51:$PORT; sleep 1; done
````
- Borrado del escenario:
```bash
kubectl delete deployment.apps/nginx-app
kubectl delete service/nginx-app
```
2 - Despliegue de un servidor nginx con tres replicas desde ficheros yaml
- Despliegue del servicio:
```bash
cd examples
kubectl apply -f nginx-web-server.yaml
kubectl apply -f nginx-service.yaml
```
- Comprobación de funcionamiento:
```bash
curl 10.20.240.51:30000
curl 10.20.240.52:30000
curl 10.20.240.53:30000
```
- Borrado del despliegue:
```bash
kubectl delete deployment.apps/nginx-web-server-pool
kubectl delete service/nginx-service
```
