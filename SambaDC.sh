#!/bin/bash
echo -e "\033[32mInstalando pacotes necessários\033[0m"

apt update -y && apt dist-upgrade -y 
apt install samba -y 
apt install winbind -y 
#apt install krb5-user -y 1>/dev/null
echo -e "\033[32mInstalando Webmin...\033[0m"
wget http://prdownloads.sourceforge.net/webadmin/webmin_2.000_all.deb
apt install -y perl libnet-ssleay-perl openssl libauthen-pam-perl \
libpam-runtime libio-pty-perl apt-show-versions python unzip shared-mime-info > /dev/null 2>&1
dpkg --install webmin_2.000_all.deb > /dev/null 2>&1

echo -e "\033[32mDesabilitando serviços desnecessários...\033[0m"
systemctl stop smbd nmbd > /dev/null 2>&1
systemctl disable smbd nmbd > /dev/null 2>&1
systemctl stop systemd-networkd > /dev/null 2>&1
systemctl disable systemd-networkd > /dev/null 2>&1

echo -e "\033[32mRemovendo configuração padrão do samba...\033[0m"
rm /etc/krb5.conf
rm /etc/samba/smb.conf

echo -e "\033[32mProvisionando o domínio...\033[0m"
echo "Digite o nome do realm. Exemplo: zeta.local"
read realm
echo -e "\033[32mDigite o nome do domínio. Exemplo: zeta\033[0m"
read domain
echo -e "\033[32mDigite a senha de administrador: \033[0m"
read password
samba-tool domain provision --use-rfc2307 --realm=$realm --domain=$domain --adminpass=$password --server-role=dc --dns-backend=SAMBA_INTERNAL

#echo "Copiando arquivos de configurações necessários"
#cp /var/lib/samba/private/krb5.conf /etc/krb5.conf

echo -e "\033[32mHabilitando o serviço\033[0m"
systemctl unmask samba-ad-dc > /dev/null 2>&1
systemctl enable samba-ad-dc > /dev/null 2>&1
systemctl stop winbind > /dev/null 2>&1
systemctl start samba-ad-dc > /dev/null 2>&1

echo -e "\033[32mAjustando DNS\033[0m"
echo "nameserver 127.0.0.1" > /etc/resolv.conf

echo -e "\033[32mAdicionando configurações necessárias\033[0m"
sudo sed -i '/^\        idmap_ldb:use rfc2307 = yes$/a\
\
        #Configurações de Log\
        log level = 3\
        log file = /var/log/samba/log.%U\
        max log size = 5000\
        timestamp logs = Yes\
\
        #Inicializacao dos Modulos VFS\
        vfs objects = dfs_samba4 acl_xattr full_audit crossrename recycle\
\
        #Configuracoes do Full Audit\
        full_audit:prefix = %u|%I|%S\
#       full_audit:success = open openfilewrite unlink rename mkdir rmdir chmod chown rm\
        full_audit:success = unlink rename chmod chown\
        full_audit:failure = all !open\
        full_audit:log_secdesc = True\
        full_audit:facility = local7\
        full_audit:priority = ALERT\
\
\
        #Configuração de restrição de pastas\
        veto files = /*.mp3\
\
' /home/vagrant/teste.txt