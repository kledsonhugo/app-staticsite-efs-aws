# Armazenamento AWS EFS (File System compartilhado) #

Amazon Elastic File System (Amazon EFS) é um serviço que fornece um sistema de arquivos elástico simples e sem servidor.

O serviço gerencia toda a infraestrutura de armazenamento de arquivos para você, evitando a complexidade de implantar, corrigir e manter configurações complexas de sistemas de arquivos.

É compatível com a última versão do protocolo Network File System versão 4 (NFSv4.1 e NFSv4.0) e suas versões anteriores.

Várias instâncias de computação em nuvem, incluindo Amazon EC2, Amazon ECS e AWS Lambda, podem acessar o sistema de arquivos EFS ao mesmo tempo, permitindo uma fonte de dados comum para cargas de trabalho e aplicativos em execução em mais de uma instância de computação.

Com o Amazon EFS, você paga apenas pelo armazenamento usado pelo sistema de arquivos e não há taxa mínima nem custo de configuração.

O objetivo é explorar na prática os conceitos deste serviço.

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

02. Em **Serviços** selecione **VPC**.

03. Selecione o botão **Criar VPC** e preencha com as informações abaixo.

    - Recursos a serem criados     : **VPC e muito mais**
    - Gerar automaticamente        : **efs**
    - Número de sub-redes privadas : **0**
    - Endpoints da VPC             : **Nenhuma**<br/><br/>

04. Clicar em **Criar VPC** e observar recursos criados conforme exemplo da figura.

    ![Criar VPC](/images/criar_vpc.png)<br/><br/>

### Criar sistema de arquivos EFS

01. Em **Serviços** selecione **EFS**.

02. Selecione o botão **Criar sistema de arquivos** e preencha com as informações abaixo.

    - Nome                    : **efs**
    - Virtual Private Cloud   : **efs-vpc**<br/><br/>

03. Clique em **Personalizar** e preencha com as informações abaixo.

    - Habilitar backups automáticos               : Desmarcar
    - Transição para IA                           : **Nenhum**
    - Habilite a criptografia de dados em repouso : Desmarcar<br/><br/>

05. Clique em **Próximo**.

06. Na tela **Acesso à rede** clique em **Próximo**.

07. Na tela **Política do sistema de arquivos - opcional** clique em **Próximo**.

08. Na tela **Revisar e criar** clique em **Criar**.

09. Após a criação deverá aparecer a mensagem **Êxito! O sistema de arquivos (fs-xxxxxxxx) está disponível** conforme exemplo da figura.

    ![Criar EFS](/images/criar_efs.png)

10. No quadro **Sistemas de arquivos** clique sobre o nome do sistema de arquivos **efs**.

11. Na aba **Rede** capture os campos **ID da sub-rede** e **Endereço IP** pois serão utilizados adiante.

    ![Criar EFS](/images/visualizar_efs.png)<br/><br/>

### Criar instâncias EC2

01. Em **Serviços** selecione **EC2**.

02. Clique em **Executar instância** e preencha com as informações abaixo.

    - Nome : **efs-public1**

    - Par de chaves (login)
      - Nome do par de chaves : **vockey** (ou outra de sua preferência)

    - Configurações de rede**
      - VPC                                     : **efs-vpc**
      - Sub-rede                                : **efs-subnet-public1-us-east-1a**
      - Atribuir IP público automaticamente     : **Habilitar**
      - Selecionar grupo de segurança existente : Selecionado
      - Grupos de segurança comuns              : **default**<br/><br/>

    - Detalhes avançados
      - AAA

    - Resumo
      - Número de instâncias : **2**

03. Clique em **Criar instância**.

04. Clique em **Visualizar todas as instâncias**.

12. Aguarde um tempo até que as instâncias fiquem com as infos abaixo.

    > Clique no botão **Refresh** para atualizar as infos

    - Estado da instância: `Executando`
    - Verificação de status: `2/2 verificações aprovadas`<br/><br/>
