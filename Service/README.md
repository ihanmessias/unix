# 💻 Machine
Esse scritp permite automatizar a verificação de informações em vários servidores e gerar um arquivo csv com as informações coletadas para facilitar a análise e tomada de decisão.

## 📜 Nota
- Em falha de ping as informações vão retornar "-" enquanto em falha de acesso é retornado "?"

            exemplo de falha de ping:
            >>> lnx0001,-,-,-,-,-
            exemplo de falha de acesso:
            >>> lnx0001,?,?,?,?,?

## 📋 Info
### SAMBA INFO:
1. O script começa verificando se o usuário que está executando o script é root. Se o usuário não for root, exibe uma mensagem informando que ele precisa ser executado como root e encerra a execução. Em seguida, se o úsuario for root define o nome do arquivo de inventário como ***“inventary.txt”*** e lê o conteúdo desse arquivo, armazenando as máquinas em um array. Por fim, cria um cabeçalho para um arquivo .csv chamado “output.csv”.
```bash
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
```
2. Este trecho de código é uma iteração que percorre cada máquina no array de máquinas. Para cada máquina, o script verifica se ela está respondendo ao comando ping. Se a máquina estiver respondendo, o script verifica se é necessário fornecer uma senha para fazer login na máquina via ssh. Se não for necessário fornecer uma senha, o script verifica se o pacote samba está instalado na máquina remota e exibe uma mensagem informando se ele está instalado ou não. Se o pacote samba não estiver instalado, o script adiciona uma linha ao arquivo *“output.csv”* com as informações da máquina e pula para a próxima máquina na iteração. Em seguida, o script verifica se o serviço smb está em execução e exibe uma mensagem informando se ele está em execução ou não. O script também verifica a versão do samba e as dependências do pacote samba na máquina remota. Por fim, verifica as últimas linhas do arquivo de log `/var/log/samba/log.smdb` e a data de modificação do arquivo `/etc/samba/smb.conf` na máquina remota. Todas essas informações são salvas no arquivo *“output.csv”*. Se for necessário fornecer uma senha ou se a máquina não estiver respondendo ao comando ping, o script adciona as linhas com base na nota informada acima.
```bash
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
```
### SAMBA REMOVE:
1. O script começa verificando se o usuário que está executando o script é root. Se o usuário não for root, exibe uma mensagem informando que ele precisa ser executado como root e encerra a execução. Em seguida, se o úsuario for root define o nome do arquivo de inventário como ***“inventary.txt”*** e lê o conteúdo desse arquivo, armazenando as máquinas em um array. Por fim, cria um cabeçalho para um arquivo .csv chamado “output.csv”.
```bash
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
```
2. Este trecho de código é uma iteração que percorre cada máquina no array de máquinas. Para cada máquina, o script verifica se ela está respondendo ao comando ping. Se a máquina estiver respondendo, o script verifica se é necessário fornecer uma senha para fazer login na máquina via ssh. Se não for necessário fornecer uma senha, o script ***define um comando para remover o pacote samba e excluir o diretório `/etc/samba`*** na máquina remota. Em seguida, o script verifica se o serviço smb está em execução e habilitado. Se estiver, o script exibe uma mensagem informando que não foi possível executar o comando de remoção, caso contrário o script executa o comando de remoção. Se for necessário fornecer uma senha ou se a máquina não estiver respondendo ao comando ping, o script adciona as linhas com base na nota informada acima.
```bash
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
```
<span style="color: red;"><strong>ATENÇÃO:</strong></span> A execução dos scripts podem sobrescrever o "Output.csv"
### 🤝 Suporte/Contato

[![Whatsapp Badge](https://img.shields.io/badge/WhatsApp-25D366?style=for-the-badge&logo=whatsapp&logoColor=white)](https://wa.me/61996487935)
[![Instagram Badge](https://img.shields.io/badge/Instagram-E4405F?style=for-the-badge&logo=instagram&logoColor=white)](https://www.instagram.com/devlinuxtv/)

✉ ihanmessias.dev@gmail.com

<p align="center">Ihan Messias Nascimento dos Santos</p>