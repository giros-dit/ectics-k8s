## Acknowledgements

This work is a result of project [ECTICS](https://www.dit.upm.es/~giros/project/ectics/) (PID2019-105257RB-C21), funded by:

![financing-logo](doc/img/MICIU_AEI_w400.jpg)

# Cluster de Kubernetes nodo central
Este repositorio incluye la información sobre los procedimientos de creación y gestión del cluster de Kubernetes del nodo central, formado por tres nodos desplegados como máquinas virtuales sobre tres de los nodos del cluster OpenStack. 

Las tres máquinas virtuales actuan como nodos que alojan contenedores (workers), actuando la primera máquina virtual, k8s-nc2, como nodo de control del cluster. Cada una de ellas tiene un interfaz en la red virtual de servicios comunes de OpenStack (red común, VLAN 3240), que se comunica con el resto de los equipos conectados a esa VLAN a través del interface physnet1 de los servidores. La conexión de los nodos está implementada como un puerto de OpenStack para que se utilice una dirección IP fija.

![Cluster Kubernetes de servicios comunes](k8s-nc.png)

El cluster incluye los servicios básicos de una infraestructura típica de Kubernetes, incluyendo un balanceador de tráfico software (MetalLB) y un proxy inverso (Ingress-NGINX). Además, se ha reservado un rango de direcciones de la VLAN 3240 (10.20.240.64/27) para asignar a las aplicaciones desplegadas en el cluster. El cluster utiliza Calico (https://www.tigera.io/project-calico/) como gestor de red del cluster (CNI) y tiene instalado el plugin Multus (https://github.com/k8snetworkplumbingwg/multus-cni) , que permite  la creación de interfaces de red adicionales en los PODs con conexión directa a las distintas VLANes de la plataforma.

## Contenido
- En el directorio [umu-nc-k8s](umu-nc-k8s) se pueden encontrar los procedimientos y scripts usados para la creación del cluster k8s.
- En el directorio [vnx-k8s](vnx-k8s) se puede encontrar el escenario virtual de pruebas del cluster diseñado para la formación en la gestión del cluster. Se incluyen varios ejemplos para el despliegue de servicios. 
