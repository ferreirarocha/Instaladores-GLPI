# Instaladores-GLPI

Esse repositório contem instaladores para o GLPI

Este script baixa  instata as Dependêcias e  realiza a configuração inicial do GLPI, usando o script nativo chamado GLPi Command Line Tools

`wget http://bit.ly/debian9glpi`

Abaixo é possível executar o script informando os parâmetros.

```bash debian9glpi2 \
-l https://github.com/glpi-project/glpi/releases/download/9.3.0/glpi-9.3.tgz \
-p senha \
-u usuario \
-b banco \
-d diretorio \
-a y
```

# Descrição das opções;
***-l***	link da versão do GLPI

***-u***	usuário

***-p***	senha

***-b***	banco

***-d***	diretório

***-a***	y (Configuração automática)

A contrabarra \ foi apenas para deixar o comando mais legível poŕem ele pode ser inserido em uma única senteça.
