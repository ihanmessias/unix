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

# Cabeçalho de arquivo .csv
echo Maquina,Samba,Status,Versão,Dependencias,Log.smdb,Smb.conf > output.csv

# Iteração
for machine in "${machines[@]}"
do
    # Verifica se a máquina está pingando
    ping -c 1 $machine > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        # Verifica se é necessário fornecer senha para logar na máquina
        ssh -o PreferredAuthentications=publickey -o ConnectTimeout=5 $machine exit 2> /dev/null
        if [ $? -eq 0 ]; then    
            # Verificando se o Samba está instalado
            if ssh $machine rpm -q samba &> /dev/null; then # zypper se -i samba &> /dev/null
                echo "Samba está instalado em $machine"
                samba="install"
            else
                echo "Samba não está instalado em $machine"
                echo $machine,not install,,,,, >> output.csv
                continue
            fi

            # Verificando se o serviço Samba está em execução:
            if ssh $machine service smb status | grep -E "is running|enabled|active \(running\)" &> /dev/null; then
                echo "Samba está em execução atualmente em $machine"
                samba_status="running"
            else
                echo "Samba não está em execução em $machine"
                samba_status="not running"
            fi

            # Verificando versão do samba:
            samba_version=$(ssh $machine smdb -V)

            # Verificando dependências 
            dependencias=$(ssh $machine rpm -q --whatrequires samba) #zypper what-requires samba
            if [ -z "$dependencias" ]; then
                echo "Nenhum serviço depende do Samba em $machine"
                samba_dp = $(echo 'not found')
            else
                echo "Os seguintes serviços dependem do Samba: $dependencias em $machine"
                samba_dp=$dependencias
            fi

            # Verificando ultima utilização
            log_smdb=$(ssh $machine tail -n 3 /var/log/samba/log.smdb | head -n 1)
            smb_conf=$(ssh $machine ls -l /etc/samba/smb.conf)

            # Salva as informações no arquivo .csv
            echo $machine,$samba,$samba_status,$samba_version,$samba_dp,$log_smdb,$smb_conf >> output.csv
            echo "Todos os dados foram capturados em $machine"
        else
        # Senha é necessária, então pula para a próxima máquina
        echo "$machine,?,?,?,?,?,?" >> output.csv
        echo "$machine >> Senha foi solicitada, pulando para o proximo"
        continue
        fi
    else
    # Máquina não está pingando, pula para a próxima máquina
        echo "$machine,-,-,-,-,-,-" >> output.csv
        echo "$machine >> Máquina sem resposta, pulando para o proximo"
        continue
    fi
done