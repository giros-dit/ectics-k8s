## Escenario de pruebas del cluster de Kubernetes

### Requisitos
Linux con VNX instalado (vnx.dit.upm.es). Receta probada sobre Ubuntu 20.04 y 22.04.

El escenario utiliza dos imágenes de VNX:
- vnx_rootfs_kvm_ubuntu64-22.04-v025.qcow2, usada para las máquinas virtuales KVM que implementan los tres nodos del cluster k8s.
- vnx_rootfs_lxc_ubuntu64-20.04-v025, usada para los contenedores auxiliares del escenario. 

Para descargarlas, ejecutar:
```bash
cd /usr/share/vnx/filesystems
vnx_download_rootfs -r vnx_rootfs_kvm_ubuntu64-22.04-v025.qcow2 -y -l
vnx_download_rootfs -r vnx_rootfs_lxc_ubuntu64-20.04-v025 -y -l
cd -
```

### Manual de usuario

- Arranque del escenario:
```bash
sudo vnx -f k8s-lab-kubeadm.xml --create
```
- Instalación del cluster:
```bash
./install-k8s    # Utilizar la opción -p para realizar una pausa entre los distintos pasos de la instalación
```
- Copiar las credenciales del cluster al host para poder acceder al cluster utilizando *kubectl*:
```bash
scp k8s-master:.kube/config ~/.kube
```

### Comprobación del funcionamiento del cluster

```bash
$ kubectl get pods -n kube-system
NAME                                      READY   STATUS    RESTARTS   AGE
calico-kube-controllers-57b57c56f-dsqfk   1/1     Running   0          35m
calico-node-ddjjh                         1/1     Running   0          35m
calico-node-fzzq9                         1/1     Running   0          35m
calico-node-rvgcd                         1/1     Running   0          35m
coredns-787d4945fb-fvk7c                  1/1     Running   0          37m
coredns-787d4945fb-mssvq                  1/1     Running   0          37m
etcd-k8s-master                           1/1     Running   0          37m
kube-apiserver-k8s-master                 1/1     Running   0          37m
kube-controller-manager-k8s-master        1/1     Running   0          37m
kube-multus-ds-5gd4p                      1/1     Running   0          34m
kube-multus-ds-ch2ns                      1/1     Running   0          34m
kube-multus-ds-whqb5                      1/1     Running   0          34m
kube-proxy-lw54x                          1/1     Running   0          37m
kube-proxy-pvnvd                          1/1     Running   0          35m
kube-proxy-xsskr                          1/1     Running   0          36m
kube-scheduler-k8s-master                 1/1     Running   0          37m
```


### Referencias

Referencias:
- How to Install Kubernetes Cluster on Ubuntu 22.04. https://www.linuxtechi.com/install-kubernetes-on-ubuntu-22-04/
- https://sangvhh.net/exposing-kubernetes-services-with-metallb-and-nginx-ingress-controller/

