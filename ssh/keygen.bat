set filename=id_rsa_%random%
ssh-keygen -t rsa -b 2048 -C "generated by %username%@%userdomain%" -f %filename%
echo %filename%