#!/bin/bash

# Verificando se o usuário é root
if [[ $(id -u) -ne 0 ]]; then
    echo "Este script precisa ser executado como root" 
    exit 1
fi

# Nome do arquivo de inventário
inventory_file="inventary.txt"

# Lê o arquivo de inventário e armazena as máquinas em um array
machines=($(cat $inventory_file))

# Iteração
for machine in "${machines[@]}"
do
    # Verifica se a máquina está pingando
    ping -c 1 $machine > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        # Verifica se é necessário fornecer senha para logar na máquina
        ssh -o PreferredAuthentications=publickey -o ConnectTimeout=5 $machine exit 2> /dev/null
        if [ $? -eq 0 ]; then
            # Define uma variável para armazenar o comando que será executado
            command="ssh $machine zypper remove -y samba && rm -rf /etc/samba"
            
            # Verifica se o serviço está parado, desabilitado ou inativo
            if ssh $machine service smb status | grep "is running" &> /dev/null && service smb status | grep "enabled" &> /dev/null; then
                echo "O serviço Samba está ativo e habilitado. Não foi possível executar o comando de remoção."
            else
                echo "O serviço Samba está parado, desabilitado ou inativo. Executando remoção..."
                $command
            fi            
        else
            # Senha é necessária, então pula para a próxima máquina
            echo "$machine >> Senha foi solicitada, pulando para o proximo"
            continue
        fi
    else
    # Máquina não está pingando, pula para a próxima máquina
        echo "$machine >> Máquina sem resposta, pulando para o proximo"
        continue
    fi
done