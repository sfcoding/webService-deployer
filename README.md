# webService-deployer

##Installation Guide (Dedian)
- Create a Git Server:
  -  useradd git
  -  passwd git
  -  apt-get install git
  -  su -m git -c "mkdir ~/.ssh && touch ~/.ssh/authorized_keys"
  -  copy your public ssh key inside the .ssh/authorized_keys file

- Install Perl 5 and the library Config::Simple (you can easyly use cpan)

- Configigure software:
  - set all path in deploy.conf
  - leave blank or add optional configuration in post-receive.conf
