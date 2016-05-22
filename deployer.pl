#!/usr/bin/perl -w
use FindBin;
$AbsPath = $FindBin::RealBin.'/';

use Config::Simple;
$cfg = new Config::Simple("${AbsPath}deployer.conf") or die "Configuration file not found\n";
$GIT_DIR = $cfg->param('GIT_DIR').'/' or die "GIT_DIR not found\n";
$DEPLOY_DIR = $cfg->param('DEPLOY_DIR').'/' or die "DEPLOY_DIR not found\n";
$NGINX_DIR = $cfg->param('NGINX_DIR').'/' or die "NGINX_DIR not found\n";

exit usage(1) unless $#ARGV >= 1;

$mode = shift @ARGV;
$appName = shift @ARGV;

while (@ARGV) {
    local $_ = shift @ARGV;
    ($_ eq '-h' || $_ eq '--help') && do { exit usage(0); };
    ($_ eq '-p' || $_ eq '--port') && do { $port = shift @ARGV; next; };
    ($_ eq '-d' || $_ eq '--domain') && do { $domain = shift @ARGV; next; };
    ($_ eq '-l' || $_ eq '--lang') && do { $appLang = shift @ARGV; next; };
    ($_ =~ /^-./) && do { print STDERR "Unknown option: $_\n"; exit usage(1); };
}

$gitPath = $GIT_DIR.$appName.'.git/';
$appPath = $DEPLOY_DIR.$appName;

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

    print "usage: deployer add|remove webService_name [options]\n";
    print "  option:\n";
    print "    -p, --port    port_number        port number for the nginx configuration file [default:80]\n";
    print "    -d, --domain  domain_name        domain name for the nginx configuration file [default: not set]\n";
    print "    -l, --lang    node|python|php  set language for dependency resolving after push event [default:php]\n";
    print "    -h, --help    show this help\n";

    select $old_fh if $old_fh;
    return $status;
}

sub add {
  #CRETE GIT REPOSITORY
  system("su git -c 'mkdir $gitPath'");
  if ( $? == 0 )
  {
    system("su git -c 'cd $gitPath && git init --bare --shared=group'");
    if ( $? == 0 )
    {
      my $gitHook = $gitPath.'hooks/';
      my $gitPostReceive = $gitHook.'post-receive';
      open HOOK, ">$gitPostReceive" or die "Can't write on hook file $gitPostReceive: $!\n";

      print HOOK "#!/bin/sh\n";
      print HOOK "git --work-tree=$appPath --git-dir=$gitPath checkout -f\n";
      print HOOK "${gitHook}post-receive.plx $appPath\n";

      system("ln -s ${AbsPath}utility/post-receive.plx ${gitHook}post-receive.plx");
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
  system("su git -c 'mkdir $appPath && chmod 775 $appPath'");
  if ( $? != 0 )
  {
    print "command failed: mkdir deploy directory $!\n";
  }

  #CREATE NGINX-CONFIG
  if (! -e $NGINX_DIR.$appName){
    $appLang = defined $appLang ? $appLang : 'php';
    $port = defined $port ? '-p '.$port : '';
    $domain = defined $domain ? '-d '.$domain : '';
    system("bash ${AbsPath}utility/nginx_create.sh $appLang -f $appPath -o $NGINX_DIR$appName $port $domain");
    if ( $? == 0 ){
      system("service nginx reload");
      if ($? != 0){
        print "command failed: reload nginx $!\n";
      }
    }else{
      print "command failed: nginx create configuration $!\n";
      exit;
    }
  }else{
    print "skip: nginx config file exists\n";
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
