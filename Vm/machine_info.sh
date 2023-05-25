#!/bin/bash

# Cria cabeçalho do arquivo .csv
echo "Server,SO,Version,IP,Hardware,Kernel" > output.csv

# Nome do arquivo de inventário
INVENTORY_FILE="inventary.txt"

# Lê o arquivo de inventário e armazena as máquinas em uma lista
machines=($(cat $INVENTORY_FILE))
# Loop para percorrer a lista de máquinas
for machine in ${machines[@]}; do
      # Verifica se a máquina está pingando
      ping -c 1 $machine > /dev/null 2>&1
      if [ $? -eq 0 ]; then
            # Verifica se é necessário fornecer senha para logar na máquina
            ssh -o PreferredAuthentications=publickey -o ConnectTimeout=5 $machine exit 2> /dev/null
            if [ $? -eq 0 ]; then
            # Obtém informações sobre o sistema operacional, IP, se é virtual ou física e versão do kernel
            IP=$(ssh $machine hostname -i)
            KERNEL=$(ssh $machine uname -r)
            # Verifica se o arquivo /etc/os-release existe
            ssh $machine test -e /etc/os-release
            if [ $? -eq 0 ]; then
                  # Se existir, obtém informações de versão do sistema operacional
                  SO=$(ssh $machine cat /etc/os-release | grep -oP '^NAME="\K[^"]+')
                  OS_VERSION=$(ssh $machine cat /etc/os-release | grep -oP '^VERSION="\K[^"]+')
            else
                  # Se não existir, obtém informações de versão do sistema operacional com lsb_release
                  SO=$(ssh $machine lsb_release -i -s)
                  OS_VERSION=$(ssh $machine lsb_release -d -s)
            fi
            # Verifica se a máquina é física ou virtual usando dmidecode
            VIRT=$(ssh $machine dmidecode -t1 | grep -oP 'Manufacturer: \K[^\n]+')
            if [ "$VIRT" == "VMware, Inc." ]; then
                  VIRT="Virtual"
            else
                  VIRT="Física"
            fi
            # Salva as informações no arquivo .csv
            echo "$machine,$SO,$OS_VERSION,$IP,$VIRT,$KERNEL" >> output.csv
            echo "Todos os dados foram capturados em $machine"
            else
            # Senha é necessária, então pula para a próxima máquina
            echo "$machine,?,?,?,?,?" >> output.csv
            echo "$machine >> Senha foi solicitada, pulando para o proximo"
            continue
            fi
      else
            # Máquina não está pingando, pula para a próxima máquina
            echo "$machine,-,-,-,-,-" >> output.csv
            echo "$machine >> Máquina sem resposta, pulando para o proximo"
            continue
      fi
done