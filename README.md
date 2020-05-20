# oci-create-base-shell

Shell Script com OCI CLI - Cria toda estrutura basica de rede para o ambiente

Para execução precisa o script e os arquivos de .env precisam estar na mesma pasta.


Compartilho com vocês meu script que desenvolvi em shell script utilizando OCI-CLI para criar ambiente automaticamente.

Utilizei muito esse script até conhecer e começar a utilizar os módulos do Terraform e dar um melhoradinha usando shell script. Pretendo criar um artigo sobre isso posteriormente.

Pré-requisito para utilização é a configuração do OCI-CLI utilizando profiles.
Caso precise configurar da OCI-CLI (https://www.linkedin.com/pulse/trabalhanco-com-oci-cli-em-multiplos-ambientes-diego-mariano/)

Ele criar toda estrutura basica de rede para o ambiente

Compartment
VCN
Security List
Route Table
Subnet
Internet Gateway
Nat Gateway
Local Peering

Ponto importante - ele cria a estrutura base do ambiente conforme o padrão que eu gosto de seguir, utilizando o mesmo nome para compartment e sua vcn principal. Se conhecer shell script básico conseguirá fazer as alterações no script para melhor atender sua necessidade.

Como funciona??

Ele lê o arquivo compartment.env e para cada linha ele chama os arquivos respectivos para criação da Subnets públicas e privadas

Cada compartment precisa ter sua subnet especificada nos arquivos com o padrão:

<Nome do Compartment>-subnet-priv.env - Subnets privadas
<Nome do Compartment>-subnet-pub.env - Subnets públicas


Para as subnets que chamo de livre, que tem como função alocar a range de IP, para manter o padrão, assim podendo recriar ela nos moldes que precisar porem os ranges já estarão definidos. O script faz validação se ela já existe mantendo apenas 1 Security List e 1 Route Table para todas as subnetes Livres

Subnet:

Adiciona a Route Table e Security List específica criada para cada Subnet
Adiciona apenas o range da própria subnet com todas as portas e protocolos na regra de ingress e adiciona todas as portas e protocolos para qualquer IP na regra de egress


Route Table

Cria rota básica de acesso para Internet utilizando Internet Gateway para subnet publica e para subnet privadas aponta para o Nat Gateway


Após a execução do script precisa adicionar as customizações para cada estrutura exemplo:

Estabelecer a comunicação entre os Local Peering e adicionar rotas para o Local Peering.

Q

