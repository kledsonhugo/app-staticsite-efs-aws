# Atividade de armazenamento AWS EFS (File System compartilhado) #

Amazon Elastic File System (Amazon EFS) é um serviço que fornece um sistema de arquivos elástico simples e sem servidor.

O serviço gerencia toda a infraestrutura de armazenamento de arquivos para você, evitando a complexidade de implantar, corrigir e manter configurações complexas de sistemas de arquivos.

É compatível com a última versão do protocolo Network File System versão 4 (NFSv4.1 e NFSv4.0) e suas versões anteriores.

Várias instâncias de computação em nuvem, incluindo Amazon EC2, Amazon ECS e AWS Lambda, podem acessar o sistema de arquivos EFS ao mesmo tempo, permitindo uma fonte de dados comum para cargas de trabalho e aplicativos em execução em mais de uma instância de computação.

Com o Amazon EFS, você paga apenas pelo armazenamento usado pelo sistema de arquivos e não há taxa mínima nem custo de configuração.

O objetivo desta atividade é explorar na prática os conceitos deste serviço.

> A execução requer conhecimento prévio sobre a infraestrutura global da AWS (Regiões e Zonas de Disponibilidade), além de caracteríticas básicas dos serviços AWS Virtual Private Cloud (VPC) e AWS Elastic Compute Cloud (EC2).

> As opções utilizadas consideram ambiente exclusivamente para experimentação. Ambientes corporativos produtivos devem levar em consideração outros aspectos não contemplados, como segurança, capacidade, alta disponibilidade e *observability*.

> Referência: [https://docs.aws.amazon.com/pt_br/efs/latest/ug/whatisefs.html](https://docs.aws.amazon.com/pt_br/efs/latest/ug/whatisefs.html)

Arquitetura base para esta atividade ([sharefs.drawio](https://github.com/FIAP/vds/blob/master/aws/efs/sharefs/sharefs.drawio))

![arquitetura base](/aws/efs/sharefs/img/shareefs.png)

## Passo 1

O primeiro passo é criar o sistema de arquivos.

1. Faça login no AWS Console.

2. Em **Serviços** selecione **EFS**.

3. Selecione o botão **Criar sistema de arquivos** e preencha com as informações abaixo.

   - Nome: `sharefs`
   - Virtual Private Cloud: Selecione uma VPC de preferência
   - Disponibilidade e durabilidade: `One Zone`
   - Zona de disponibilidade: Selecione uma zona de disponibilidade de preferência

     > Guarde a informação **VPC** pois será necessária adiante.
     > Mantenha as demais opções padrões.

4. Clique em **Personalizar** e preencha com as informações abaixo.

   - Backups automáticos: Desmarque a opção **Habilitar backups automáticos**
   - Gerenciamento de ciclo de vida: `Nenhum`
   - Criptografia: Desmarque a opção **Habilite a criptografia de dados em repouso**

     > Mantenha as demais opções padrões.

5. Clique em **Próximo**.

6. Na tela **Acesso à rede** clique em **Próximo**.

7. Na tela **Política do sistema de arquivos - opcional** clique em **Próximo**.

8. Na tela **Revisar e criar** clique em **Criar**.

9. Após a criação deverá aparecer a mensagem **Êxito! O sistema de arquivos (fs-xxxxxxxx) está disponível**.

10. No quadro **Sistemas de arquivos** clique sobre o nome do sistema de arquivos.

11. Na aba **Rede** capture os campos **ID da sub-rede** e **Endereço IP** pois serão utilizados adiante.


## Passo 2

Inicie instâncias EC2.

1. Em **Serviços** selecione **EC2**.

2. Clique em **Executar instância**.

3. Na tela **Etapa 1: Selecione uma Imagem de máquina da Amazon (AMI)** selecione a opção **Amazon Linux 2 AMI** e clique em **Selecionar**.

   > Mantenha as demais opções padrões.

4. Na tela **Etapa 2: Escolha um tipo de instância** selecione a opção **t2.micro** e clique em **Próximo**.

5. Na tela **Etapa 3: Configure os detalhes da instância** preencha com as informações abaixo e clicar em **Próximo: Adicionar armazenamento**.

   - Número de instâncias: `2`
   - Rede: Selecione a VPC utilizada no passo anterior
   - Sub-rede: Selecione o ID da Sub-rede utilizada no passo anterior
   - Dados do usuário: Copie e cole o conteúdo abaixo
     ```
     sudo yum -y update 
     sudo yum -y install nfs-utils
     ```

     > Mantenha as demais opções padrões.

6. Na tela **Etapa 4: Adicionar armazenamento** clique em **Próximo: Adicionar Tags**.

7. Na tela **Etapa 5: Adicionar Tags** clique em **Próximo: Configure o security group**.

8. Na tela **Etapa 6: Configure o security group** selecione um **Grupo de Segurança** que contenha a regra abaixo e clique em **Verificar e ativar**.

   - Type: `All traffic`
   - Protocol: `All`
   - Port Range: `All`
   - Source: `0.0.0.0/0`

9. Na tela **Etapa 7: Review Instance Launch** clicar em **Executar**.

10. Na tela **Selecione um par de chaves ...** selecione um par de chaves existe ou crie um novo par de chaves e clique em **Executar**.

    > Guarde a chave pois será necessária adiante.

11. Na tela **Launch Status** clique em **Exibir instâncias**.

12. Aguarde um tempo até que as instâncias fiquem com as infos abaixo. Clique no botão **Refresh** para atualizar as infos.

    - Estado da instância: `Executando`
    - Verificação de status: `2/2 verificações aprovadas`

      > Guarde a informação **DNS IPv4 público** de cada instância pois serão necessárias adiante.


## Passo 3

Configure as instâncias para utilizarem de forma compartilhada o sistema de arquivos criado no primeiro passo.

1. Abra um terminal ssh e conecte nas instâncias EC2.

   > Na figura abaixo com [MobaXterm](https://mobaxterm.mobatek.net/download-home-edition.html), os seguintes campos foram preenhidos

     - Remote host: **DNS IPv4 público**
     - Specify username: `ec2-user`
     - Use private key: arquivo com a chave utilizada durante criação da instância

     ![terminal ssh](/aws/efs/sharefs/img/ssh-connect.PNG)

2. Realize a montagem do sistema de arquivos com os comandos abaixo nas duas instâncias.

   > Substitua `{Endereço IP}` pelo valor capturado no primeiro passo dessa atividade.
   ```
   sudo -i
   mkdir /opt/sharefs
   mount -t nfs -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport {Endereço IP}:/ /opt/sharefs
   ```

3. Crie um arquivo na primeira instância e verifique na outra instãncia se o arquivo existe.

   Na primeira instância
   ```
   touch /opt/sharefs/file_a
   ls -la /opt/sharefs/
   ```

   Na segunda instância
   ```
   ls -la /opt/sharefs/
   ```
