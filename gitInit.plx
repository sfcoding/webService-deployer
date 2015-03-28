#!/usr/bin/perl -w

use Config::Simple;
$cfg = new Config::Simple('app.conf');
$GIT_DIR = $cfg->param('GIT_DIR').'/';
$DEPLOY_DIR = $cfg->param('DEPLOY_DIR').'/';
$NGINX_DIR = $cfg->param('NGINX_DIR').'/';
use FindBin;
$AbsPath = $FindBin::RealBin.'/';

exit usage(1) unless $#ARGV >= 1;

$mode = shift @ARGV;
$appName = shift @ARGV;

while (@ARGV) {
    local $_ = shift @ARGV;
    ($_ eq '-h' || $_ eq '--help') && do { exit usage(0); };
    ($_ eq '-p' || $_ eq '--port') && do { $port = shift @ARGV; next; };
    ($_ eq '-d' || $_ eq '--domain') && do { $domain = shift @ARGV; next; };
    ($_ eq '-l' || $_ eq '--lang') && do { $ appLang= shift @ARGV; next; };
    ($_ =~ /^-./) && do { print STDERR "Unknown option: $_\n"; exit usage(1); };
}

$gitPath = $GIT_DIR.$appName.'.git/';
$appPath = $DEPLOY_DIR.$appName;

#mkdir repo && cd repo
#mkdir site.git && cd site.git
#git init --bare

if ($mode eq 'add'){
  add();
}
elsif ($mode eq 'remove'){
  remove();
}else{
  exit usage(1);
}

sub usage {
    my ($status) = @_;
    my $old_fh = select STDERR if $status;

    print 'asdasd';

    select $old_fh if $old_fh;
    return $status;
}

sub add {
  #CRETE GIT REPOSITORY
  system("su -m git -c 'mkdir $gitPath'");
  if ( $? == 0 )
  {
    system("su -m git -c 'git -C $gitPath init --bare'");
    if ( $? == 0 )
    {
      my $gitHook = $gitPath.'hooks/';
      my $gitPostReceive = $gitHook.'post-receive';
      open HOOK, ">$gitPostReceive" or die "Can't write on hook file $gitPostReceive: $!\n";

      print HOOK "#!/bin/sh\n";
      print HOOK "git --work-tree=$appPath --git-dir=$gitPath checkout -f\n";
      print HOOK "${gitHook}post-receive.plx $appPath\n";

      system("ln -s ${AbsPath}post-receive.plx ${gitHook}post-receive.plx");
      system("chown git:git $gitPostReceive && chmod 755 $gitPostReceive");
      if ( $? != 0 )
      {
        print "command failed: git hook creation $!\n";
        exit;
      }
    }else{
      print "command failed: git init $!\n";
    }
  }else{
    print "command failed: mkdir git folder $!\n";
  }

  #CREATE DEPLOY DIRECTORY
  system("su -m git -c 'mkdir $appPath'");
  if ( $? != 0 )
  {
    print "command failed: mkdir deploy directory $!\n";
  }

  #CREATE NGINX-CONFIG
  $appLang = defined $appLang ? $appLang : 'html';
  $port = defined $port ? '-p '.$port : '';
  $domain = defined $domain ? '-d '.$domain : '';
  system("bash ./nginx_create.sh $appLang -f $appPath -o $NGINX_DIR$appName $port $domain");
  if ( $? == 0 ){
    system("service nginx reload");
    if ($? != 0){
      print "command failed: reload nginx $!\n";
    }
  }else{
    print "command failed: nginx create configuration $!\n";
    exit;
  }
}

sub remove {
  system("rm -Rf $gitPath");
  if ( $? != 0 )
  {
    print "command failed: remove git repository $!\n";
    exit;
  }

  system("rm -Rf $appPath");
  if ( $? != 0 )
  {
    print "command failed: remove deploy directory $!\n";
  }

  system("rm -f $NGINX_DIR$appName");
  if ( $? == 0 ){
    system("service nginx reload");
    if ($? != 0){
      print "command failed: reload nginx $!\n";
    }
  }else{
    print "command failed: nginx remove configuration $!\n";
    exit;
  }
}
