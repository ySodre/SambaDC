#!/bin/bash
echo -e "\033[32mATUALIZANDO O SISTEMA...\033[0m\n"

apt update -y > /dev/null 2>&1
apt dist-upgrade -y  > /dev/null 2>&1
echo -e "\033[32mINSTALANDO SAMBA...\033[0m\n"
apt install samba -y  > /dev/null 2>&1
echo -e "\033[32mINSTALANDO WINBIND...\033[0m\n"
apt install winbind -y  > /dev/null 2>&1
#apt install krb5-user -y 1>/dev/null
echo -e "\033[32mINSTALANDO WEBMIN...\033[0m\n" 
wget http://prdownloads.sourceforge.net/webadmin/webmin_2.000_all.deb > /dev/null 2>&1
apt install -y perl libnet-ssleay-perl openssl libauthen-pam-perl \
libpam-runtime libio-pty-perl apt-show-versions python unzip shared-mime-info > /dev/null 2>&1
dpkg --install webmin_2.000_all.deb > /dev/null 2>&1

echo -e "\033[32mDESABILITANDO SERVIÇOS DESNECESSÁRIOS...\033[0m\n"
systemctl stop smbd nmbd > /dev/null 2>&1
systemctl disable smbd nmbd > /dev/null 2>&1
systemctl stop systemd-networkd > /dev/null 2>&1
systemctl disable systemd-networkd > /dev/null 2>&1

echo -e "\033[32mREMOVENDO ARQUIVOS DE CONFIGURAÇÃO PADRÃO...\033[0m\n"
rm /etc/samba/smb.conf

echo -e "\033[32mPROVISIONANDO O DOMÍNIO...\033[0m\n"
echo -e "\033[32mDIGITE O NOME DO DOMÍNIO COMPLETO EX: zeta.local\033[0m\n"
read realm
echo -e "\033[32mDIGITE O NOME DO DOMÍNIO APENAS O PRIMEIRO NOME EX: zeta\033[0m\n"
read domain
echo -e "\033[32mDEFINA UMA SENHA DE ADMINISTRADOR: \033[0m\n"
read password
samba-tool domain provision --use-rfc2307 --realm=$realm --domain=$domain --adminpass=$password --server-role=dc --dns-backend=SAMBA_INTERNAL > /dev/null 2>&1
dpkg --install webmin_2.000_all.deb > /dev/null 2>&1

#echo "Copiando arquivos de configurações necessários"
#cp /var/lib/samba/private/krb5.conf /etc/krb5.conf

echo -e "\033[32mHABILITANDO O SERVIÇO...\033[0m\n"
systemctl unmask samba-ad-dc > /dev/null 2>&1
systemctl enable samba-ad-dc > /dev/null 2>&1
systemctl stop winbind > /dev/null 2>&1
systemctl start samba-ad-dc > /dev/null 2>&1

echo -e "\033[32mAJUSTANDO DNS...\033[0m\n"
echo "nameserver 127.0.0.1" > /etc/resolv.conf

echo -e "\033[32mFINALIZANDO CONFIGURAÇÕES...\033[0m\n"
sudo sed -i '/^\       idmap_ldb:use rfc2307 = yes$/a\
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
' /etc/samba/smb.conf

echo -e "\033[32mINSTALAÇÃO FINALIZADA!!!\033[0m"