# 💻 Machine Info:
Esse scritp permite automatizar a verificação de informações em vários servidores e gerar um arquivo csv com as informações coletadas para facilitar a análise e tomada de decisão.

## 📜 Nota
- Em falha de ping as informações vão retornar "-" enquanto em falha de acesso é retornado "?"

            exemplo de falha de ping:
            >>> lnx0001,-,-,-,-,-
            exemplo de falha de acesso:
            >>> lnx0001,?,?,?,?,?

## 📋 Info
1. O script começa com a declaração de um cabeçalho **"#!/bin/bash"** que indica que é um script de shell. Em seguida, ele cria um arquivo de saída chamado **"output.csv"** usando o comando **"echo"** e adiciona uma linha de cabeçalho com o nome das colunas.
```bash
#!/bin/bash

# Cria cabeçalho do arquivo .csv
echo "Server,SO,Version,IP,Hardware,Kernel" > output.csv
```
2. O script então estabelece duas variaveis para ler cada linha do arquivo **"inventary.txt"** e armazena o nome de host em uma lista chamada **"HOSTS"**. O script então entra em uma iteração para percorrer cada servidor na variável **"HOST"**.
```bash
# Nome do arquivo de inventário
INVENTORY_FILE="inventary.txt"

# Lê o arquivo de inventário e armazena as máquinas em uma lista
HOSTS=($(cat $INVENTORY_FILE))
# Iteração para percorrer a lista de máquinas
for HOST in ${HOSTS[@]}; do
```

3. Em cada iteração, o script verifica se a máquina está pingando, se estiver, prossegue para a verificação se é necessário fornecer senha para logar na máquina. Se não for necessário fornecer senha, o script obtém as informações sobre o **sistema operacional, IP, se é virtual ou física e versão do kernel**. Ele também verifica se o arquivo /etc/os-release existe, se não existir, obtém informações com lsb_release. Depois de todo processo as informações coletadas são salvas no arquivo CSV.
```bash
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
```


### 🤝 Suporte/Contato

[![LinkedIn Badge](https://img.shields.io/static/v1?style=for-the-badge&message=LinkedIn&color=0A66C2&logo=LinkedIn&logoColor=FFFFFF&label=)](https://www.linkedin.com/in/ihanmessias/)
[![Whatsapp Badge](https://img.shields.io/badge/WhatsApp-25D366?style=for-the-badge&logo=whatsapp&logoColor=white)](https://wa.me/61996487935)
[![Instagram Badge](https://img.shields.io/badge/Instagram-E4405F?style=for-the-badge&logo=instagram&logoColor=white)](https://www.instagram.com/devlinuxtv/)

✉ ihanmessias.dev@gmail.com

<p align="center">Ihan Messias Nascimento dos Santos</p>
