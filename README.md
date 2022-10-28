# WebApp hosted on AWS EFS

Amazon Elastic File System (Amazon EFS) é um serviço que fornece um sistema de arquivos elástico simples e sem servidor.

O serviço gerencia toda a infraestrutura de armazenamento de arquivos para você, evitando a complexidade de implantar, corrigir e manter configurações complexas de sistemas de arquivos.

É compatível com a última versão do protocolo Network File System versão 4 (NFSv4.1 e NFSv4.0) e suas versões anteriores.

Várias instâncias de computação em nuvem, incluindo Amazon EC2, Amazon ECS e AWS Lambda, podem acessar o sistema de arquivos EFS ao mesmo tempo, permitindo uma fonte de dados comum para cargas de trabalho e aplicativos em execução em mais de uma instância de computação.

Com o Amazon EFS, você paga apenas pelo armazenamento usado pelo sistema de arquivos e não há taxa mínima nem custo de configuração.

O objetivo é explorar na prática os conceitos deste serviço.

  > **Note**

  > A execução requer conhecimento prévio sobre a infraestrutura global da AWS (Regiões e Zonas de Disponibilidade), além de caracteríticas básicas dos serviços AWS Virtual Private Cloud (VPC) e AWS Elastic Compute Cloud (EC2).

  > As opções utilizadas consideram ambiente exclusivamente para experimentação. Ambientes corporativos produtivos devem levar em consideração outros aspectos não contemplados, como segurança, capacidade, alta disponibilidade e *observability*.

  > Referência: [https://docs.aws.amazon.com/pt_br/efs/latest/ug/whatisefs.html](https://docs.aws.amazon.com/pt_br/efs/latest/ug/whatisefs.html)

<br/><br/>
## Arquitetura de referência

![arquitetura base](/images/app-static-site-efs.png)

<br/><br/>
## Passo-a-passo<br/><br/>

### Criar VPC

01. Faça login no AWS Console.

02. Em **Serviços** digite **VPC** e selecione o serviço.

03. Selecione o botão **Criar VPC** e preencha com as informações abaixo.

    - Recursos a serem criados     : **VPC e muito mais**
    - Gerar automaticamente        : **efs**
    - Bloco CIDR IPv4              : **10.0.0.0/16**
    - Número de sub-redes privadas : **0**
    - Endpoints da VPC             : **Nenhuma**<br/><br/>

04. Clicar em **Criar VPC**.

05. Observar se os recursos associados à VPC foram criados conforme o exemplo da figura.

    > **Note**

    > Valide cuidadosamente esse passo antes de prosseguir. Esse passo é pré-requisito para os demais passos desse procedimento. Em caso de dúvidas ou algo inesperado, não prossiga, busque apoio.

    - Devem ser criados:
      - 01 VPC
      - 02 Sub-Redes
      - 01 Gateway para a Internet
      - 01 Tabela de Rotas padrão<br/><br/>

      ![Criar VPC](/images/criar_vpc.png)<br/><br/>

    > **Warning**

    >W> Ignore a mensagem *Falha ao carregar grupos de regras* conforme figura abaixo, caso apareça. Essa mensagem é devido a ambientes de laboratório não possuirem permissão para visualizar regras do firewall de DNS. Essa mensagem não afeta os passos seguintes dessa atividade.

    ![Criar VPC](/images/criar_vpc_falha_ao_carregar_grupos.png)<br/><br/>

### Criar Security Group (Firewall)

01. Em **Serviços** digite **VPC** e selecione o serviço.

02. No menu lateral esquerdo clique em **Grupos de segurança**.

03. Clique em **Criar grupo de segurança** e preencha com as informações abaixo.

    - Nome do grupo de segurança : **efs-sg**
    - Descrição                  : **EFS Security Group**
    - VPC                        : **efs-vpc**<br/><br/>
    - Em **Regras de entrada** clique em **Adicionar regra** para cada regra abaixo
      - Regra
        - Tipo   : **Todo o tráfego**
        - Origem : **10.0.0.0/16**
      - Regra
        - Tipo   : **SSH**
        - Origem : **0.0.0.0/0**
      - Regra
        - Tipo   : **HTTP**
        - Origem : **0.0.0.0/0**<br/><br/>

04. Clique em **Criar grupo de segurança**.<br/><br/>

### Criar sistema de arquivos EFS

01. Em **Serviços** digite **EFS** e selecione o serviço.

02. Selecione o botão **Criar sistema de arquivos** e preencha com as informações abaixo.

    - Nome                    : **efs**
    - Virtual Private Cloud   : **efs-vpc**<br/><br/>

03. Clique em **Personalizar** e preencha com as informações abaixo.

    - Habilitar backups automáticos               : Desmarcar
    - Transição para IA                           : **Nenhum**
    - Habilite a criptografia de dados em repouso : Desmarcar<br/><br/>

04. Clique em **Próximo**.

05. Na tela **Acesso à rede**, para cada uma das duas Zonas de disponibilidade, remova o grupo de segurança padrão e selecione o grupo de segurança **efs-sg** .

    > **Note**

    > As subnets criadas anteriormente devem ser preenchidas automaticamente no campo *ID da sub-rede*.
    
    > A sub-rede *efs-subnet-public1-us-east-1x* para uma Zona de disponibilidade e a sub-rede *efs-subnet-public2-us-east-1x* para a outra Zona de disponibilidade.
    
    > Caso não estejam, selecione manualmente.

06. Clique em **Próximo**.

07. Na tela **Política do sistema de arquivos** clique em **Próximo**.

08. Na tela **Revisar e criar** clique em **Criar**.

09. Após a criação deverá aparecer a mensagem **Êxito! O sistema de arquivos com id fs-*xxxxxxxx* está disponível** conforme exemplo da figura.

    > **Note**
    
    > Capture o id do sistema de arquivos pois será utilizado adiante.

    ![Criar EFS](/images/criar_efs.png)<br/><br/>

### Criar instâncias EC2

01. Em **Serviços** digite **EC2** e selecione o serviço.

02. Clique em **Executar instância** e preencha com as informações abaixo.

    - Nome : **efs-public1**

    - **Par de chaves (login)**
      - Nome do par de chaves : **vockey** (ou outra de sua preferência)<br/><br/>

    - Clique em **Editar** em **Configurações de rede**
      - VPC                                 : **efs-vpc**
      - Sub-rede                            : **efs-subnet-public1-us-east-1a**
      - Atribuir IP público automaticamente : **Habilitar**
      - **Selecionar grupo de segurança existente**
        - Grupos de segurança comuns : **efs-sg**<br/><br/>

    - **Detalhes avançados**
      - Dados do usuário

        ```
        #!/bin/bash
        yum update -y
        amazon-linux-extras install -y php7.2 epel
        yum install -y amazon-efs-utils httpd telnet tree git
        mkdir /mnt/efs
        echo "${efs_id}:/ /mnt/efs efs _netdev,noresvport,tls 0 0" >> /etc/fstab
        x=10
        while (( $x > 0 )); do
          mount -fav
          mnt=`df -h |grep /mnt/efs |wc -l`
          if (( $mnt >= 1 )); then
            systemctl enable httpd
            cd /tmp
            git clone https://github.com/kledsonhugo/app-static-site-efs
            mkdir /mnt/efs/html
            cp /tmp/app-static-site-efs/app/*.html /mnt/efs/html
            cp /tmp/app-static-site-efs/app/phpinfo.php /mnt/efs/html
            rm -rf /var/www/html/
            ln -s /mnt/efs/html/ /var/www/html
            service httpd restart
            break
          fi
          echo $((x--))
          echo "Unable to mount EFS. Attempt: $x"
          sleep 5
        done
        ```

        > **Note**

        > Substitua no código acima **${efs-id}** pelo id do sistema de arquivos capturado anteriormente, conforme figuras abaixo.

        > **Antes**
        ![Criar EFS](/images/criar_ec2_userdata_before.png)<br/><br/>

        > **Depois**
        
        > EFS id *fs-0e1404bfc151ce59b* usado apenas como exemplo. Substitua pelo id do EFS criado previamente nessa atividade.
        ![Criar EFS](/images/criar_ec2_userdata_after.png)<br/><br/>

    - **Resumo**
      - Número de instâncias : **2**<br/><br/>

03. Clique em **Executar instância**.

04. Clique em **Visualizar todas as instâncias**.

05. Aguarde até que as instâncias fiquem com o status **2/2 verificações aprovadas** conforme exemplo da figura.

    > **Note**

    > Clique no botão **Refresh** para atualizar o status da página.

    ![Visualizar Instancias](/images/visualizar_instancias.png)<br/><br/>

    > **Note**

    > Valide cuidadosamente esse passo antes de prosseguir. Esse passo é pré-requisito para os demais passos desse procedimento. Em caso de dúvidas ou algo inesperado, não prossiga e busque apoio.

    <br/><br/>
    
06. Repita os passos 01 ao 05 acima apenas alterando com as informações abaixo.

    - Nome : **efs-public2**

    - **Configurações de rede**
      - Sub-rede : **efs-subnet-public2-us-east-1b**

        > **Note**
        
        > Pode ser que a sub-rede não seja **efs-subnet-public2-us-east-*1b***, dependendo de qual Zona de disponibilidade a sub-rede foi criada. Porém nesse ponto não pode ser a mesma sub-rede usada para criar as primeiras 2 instâncias EC2.
        
        > Veja a [Arquitetura de Referência](/images/visualizar_instancias.png).
        
        > Em caso de dúvidas busque por apoio.
    
    <br/><br/>


### Criar Balanceador de Carga

01. Em **Serviços** digite **EC2** e selecione o serviço.

02. No menu lateral esquerdo clique em **Grupos de destino**.

03. Clique em **Criar grupo de destino** e preencha com as informações abaixo.

    - Nome do grupo de destino : **efs-elb-target-group**
    - VPC                      : **efs-vpc**<br/><br/>

04. Clique em **Próximo**.

05. Selecione as 4 instâncias criadas anteriormente, que iniciam com **efs-publc**, e clique em **Incluir como pendente abaixo** conforme exemplo da figura.

    ![Visualizar instâncias target](/images/visualizar_instancias_target.png)

06. Validar se as 4 instâncias foram movidas para a área **Examinar destinos** conforme exemplo da figura.

    ![Visualizar instâncias target 2](/images/visualizar_instancias_target2.png)

07. Clique em **Criar grupo de destino**.

08. No menu lateral esquerdo clique em **Load Balancers**.

09. Clique em **Criar Load Balancer**.

10. Clique em **Criar** para a opção **Application Load Balancer** e preencha com as informações abaixo.

    - Nome        : **efs-elb**
    - VPC         : **efs-vpc**
    - Mapeamentos : **us-east-1a** e **us-east-1b**
      
      > **Note**

      > A segunda Zona de disponibilidade pode não ser **us-east-1b**, dependendo de qual Zona de disponibilidade as sub-redes foram criadas. Selecione as Zonas de disponibilidade usadas para criar as instâncias EC2.
      
      > Em caso de dúvidas busque por apoio.

    - Grupos de segurança : **efs-sg**
      
      > **Note**

      > Desmarque qualquer outro Grupo de Segurança que por ventura já estava selecionado por padrão.

    - Ação padrão : Avançar para **efs-elb-target-group**<br/><br/>

11. Clique em **Criar Load Balancer**.

12. Clique em **Ver balanceador de carga**.

13. Aguarde até que o balanceador de carga fique com o estado **Ativo** conforme exemplo da figura.

    > **Note**
    
    > Clique no botão **Refresh** para atualizar o estado

    ![Visualizar ELB](/images/visualizar_elb.png)

14. Capturar a url do campo **Nome do DNS**.

15. No menu lateral esquerdo clique em **Grupos de destino**.

16. Clicar sobre o **Grupo de destino** previamente criado **efs-elb-target-group**.

17. Valide se o Balanceador de Carga possui 4 instâncias com status **Íntegro**, conforme exemplo da figura.

    > **Note**

    > Valide cuidadosamente esse passo antes de prosseguir.
    
    > Esse passo é pré-requisito para os demais passos desse procedimento.
    
    > Em caso de dúvidas ou algo inesperado, não prossiga, busque apoio.

    ![Visualizar ELB](/images/visualizar_grupo_destino.png)

### Testar aplicação HTML

01. Abrir uma outra guia do navegador e acessar a url do Balanceador de Carga capturada previamente, conforme exemplo da figura.

    ![Visualizar ELB](/images/visualizar_aplicação.png)

### Testar Balanceador de Carga

01. Na mesma guia do navegador, inclua **/phpinfo.php** no fim da url, conforme exemplo da figura.

    ![Visualizar ELB](/images/visualizar_aplicação_balanceador.png)

02. Atualize a página e observe se a informação da linha **System** é alterada conforme os exemplos abaixo.

    ![Visualizar ELB](/images/visualizar_aplicação_balanceador_1.png)

    ![Visualizar ELB](/images/visualizar_aplicação_balanceador_2.png)

    > **Note**

    > Toda vez que a página é carregada, o balanceador de carga direciona a conexão para uma das 4 instâncias.
    
    > Atualize o browser algumas vezes, até que o IP das 4 instâncias EC2 apareça.
    
    > **Warning**
    
    > Se não aparecerem 4 IP´s diferentes, não existem 4 instâncias EC2 íntegras no balanceador de carga.

<br/><br/>
## Parabéns

Se chegou até aqui você concluiu com sucesso o objetivo proposto dessa atividade

Parabéns !!!

Não esqueça de desproisionar todos recursos criados nessa atividade, para evitar gastos desnecessários.