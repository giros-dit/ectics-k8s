## Escenario de pruebas del cluster de Kubernetes

### Requisitos
Linux con VNX instalado (vnx.dit.upm.es). Receta probada sobre Ubuntu 20.04 y 22.04.

El escenario utiliza dos imágenes de VNX:
- vnx_rootfs_kvm_ubuntu64-22.04-v025.qcow2
- vnx_rootfs_lxc_ubuntu64-20.04-v025

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



### Referencias

Referencias:
- How to Install Kubernetes Cluster on Ubuntu 22.04. https://www.linuxtechi.com/install-kubernetes-on-ubuntu-22-04/
- https://sangvhh.net/exposing-kubernetes-services-with-metallb-and-nginx-ingress-controller/

