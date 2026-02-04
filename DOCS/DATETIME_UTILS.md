# Gerenciador de Data e Hora - Ubuntu Server

Script bash completo para gerenciamento de data, hora e fuso horário em sistemas Ubuntu Server.

## 🚀 Características

- ✅ Interface de menu interativo e colorido
- ✅ Verificar status completo do sistema (data, hora, RTC, NTP)
- ✅ Ajustar data (ano, mês, dia)
- ✅ Ajustar hora (hora, minuto, segundo)
- ✅ Configurar relógio de hardware (UTC ou hora local)
- ✅ Listar todos os fusos horários disponíveis
- ✅ Ajustar fuso horário com lista pré-definida do Brasil
- ✅ Sincronizar relógio do sistema com hardware e vice-versa
- ✅ Ativar/desativar sincronização NTP
- ✅ Forçar sincronização com servidores NTP
- ✅ Validação de entradas

## 📋 Requisitos

- Ubuntu Server (18.04+)
- Privilégios de root (sudo)
- Pacotes: `systemd`, `util-linux`

## 🔧 Instalação

1. Baixe o script:
```bash
wget https://seu-servidor.com/datetime-manager.sh
```

2. Torne-o executável:
```bash
chmod +x datetime-manager.sh
```

3. Execute com privilégios de root:
```bash
sudo ./datetime-manager.sh
```

## 📖 Como Usar

### Menu Principal

Ao executar o script, você verá um menu com as seguintes opções:

```
MENU PRINCIPAL

 1) Verificar status de data e hora
 2) Ajustar data (ano, mês, dia)
 3) Ajustar hora (hora, minuto, segundo)
 4) Configurar relógio de hardware (UTC/Local)
 5) Listar fusos horários disponíveis
 6) Ajustar fuso horário
 7) Sincronizar relógio
 8) Configurar NTP (ativar/desativar)
 9) Sair
```

### Exemplos de Uso

#### 1. Verificar Status
Mostra informações completas sobre:
- Data e hora do sistema
- Data e hora do hardware (RTC)
- Fuso horário atual
- Status do NTP
- Detalhes do timedatectl

#### 2. Ajustar Data
```
Digite o ANO (ex: 2024): 2024
Digite o MÊS (01-12): 02
Digite o DIA (01-31): 15
```

#### 3. Ajustar Hora
```
Digite a HORA (00-23): 14
Digite os MINUTOS (00-59): 30
Digite os SEGUNDOS (00-59): 00
```

#### 4. Configurar RTC
Escolha se o relógio de hardware usa:
- **UTC** (recomendado para servidores)
- **Hora Local** (necessário para dual-boot com Windows)

#### 5. Ajustar Fuso Horário

##### Opção 1: Lista do Brasil
Fusos horários brasileiros pré-configurados:
- Fernando de Noronha (UTC-2)
- Nordeste (UTC-3)
- São Paulo, Sul e Sudeste (UTC-3)
- Mato Grosso e MS (UTC-4)
- Amazonas (UTC-4)
- Acre (UTC-5)

##### Opção 2: Manual
Digite o fuso horário completo:
```
America/Sao_Paulo
Europe/London
Asia/Tokyo
```

##### Opção 3: Buscar por Região
Busque fusos horários filtrando por continente ou região

#### 6. Sincronizar Relógio

Três opções de sincronização:
1. **Sistema → Hardware**: Atualiza o RTC com a hora do sistema
2. **Hardware → Sistema**: Atualiza o sistema com a hora do RTC
3. **Forçar NTP**: Sincroniza imediatamente com servidores NTP

#### 7. Configurar NTP

- Ativar sincronização automática com servidores de tempo
- Desativar quando precisar ajustar manualmente
- Ver status detalhado da sincronização
- Reiniciar o serviço NTP

## ⚙️ Configurações Importantes

### Quando usar UTC no RTC?
- ✅ Servidores Linux
- ✅ Sistemas virtualizados
- ✅ Dual-boot apenas com Linux
- ✅ Ambiente de produção

### Quando usar Hora Local no RTC?
- ⚠️ Dual-boot com Windows
- ⚠️ Necessidade específica de aplicações legadas

### NTP Ativo vs Desativado

**NTP Ativo:**
- Sincronização automática com servidores de tempo
- Hora sempre precisa
- Recomendado para servidores em produção

**NTP Desativado:**
- Necessário para ajustar data/hora manualmente
- Útil em ambientes isolados sem internet
- Requer sincronização manual periódica

## 🛠️ Comandos Úteis do Sistema

O script utiliza os seguintes comandos do sistema:

```bash
# Ver status completo
timedatectl status

# Listar fusos horários
timedatectl list-timezones

# Definir fuso horário
timedatectl set-timezone America/Sao_Paulo

# Ativar/desativar NTP
timedatectl set-ntp true
timedatectl set-ntp false

# Sincronizar com hardware
hwclock --systohc

# Ver hora do hardware
hwclock --show
```

## 🐛 Solução de Problemas

### NTP não sincroniza
```bash
# Verificar status do serviço
systemctl status systemd-timesyncd

# Reiniciar serviço
sudo systemctl restart systemd-timesyncd

# Ver logs
journalctl -u systemd-timesyncd
```

### Erro ao ajustar data/hora
1. Verifique se está rodando como root
2. Desative o NTP temporariamente
3. Verifique se a data é válida

### Fuso horário não encontrado
1. Liste os fusos disponíveis (opção 5)
2. Use o nome exato com capitalização correta
3. Exemplo: `America/Sao_Paulo` (não `america/sao_paulo`)

## 📝 Notas

- O script desativa temporariamente o NTP ao ajustar data/hora manualmente
- Todas as alterações são aplicadas imediatamente no sistema
- Recomenda-se manter o NTP ativo em ambientes de produção
- O relógio de hardware (RTC) é persistente após reinicializações

## 📄 Licença

Este script é fornecido "como está", sem garantias de qualquer tipo.

## 🤝 Contribuições

Sinta-se à vontade para melhorar este script e adaptá-lo às suas necessidades.

## 📧 Suporte

Para problemas ou sugestões, consulte a documentação do Ubuntu Server ou do systemd-timesyncd.