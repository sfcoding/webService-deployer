#!/usr/bin/perl -w
use Config::Simple;
use Cwd;
use FindBin;
$AbsPath = $FindBin::RealBin.'/';

die "parameter error\n" unless ($#ARGV == 0);
$rootDir = $ARGV[0];

Config::Simple->import_from("${AbsPath}post-receive.conf", \%cfg);
$virtualenv = $cfg{'VIRTUALENV_PATH'} or chomp ($virtualenv=`which virtualenv`);
$npm = $cfg{'NPM_PATH'} or chomp ($npm=`which npm`);

$runtimeFile = $rootDir.'/runtime.txt';
if (-e $runtimeFile) {
  #%cfgRuntime = $cfg->vars();
  open RUNTIME, "<", $runtimeFile or die $!;
  $language = <RUNTIME>;
  chomp $language;
  #print "language: $language , $cfgRuntime{$language}\n";
  $runtime = $cfg{$language}
    or chomp ($runtime = `which $language`)
    or die "error runtime $language not found\n";
    
  print "found runtime $runtime\n";

  $requirements = $rootDir.'/requirements.txt';
  $package = $rootDir.'/package.json';
  if (-e $requirements) {
    python();
  }elsif (-e $package){
    node();
  }else{
    die "no package.json or requirement.txt found\n";
  }

  if (! -e $rootDir.'/public'){
    system("mkdir ${rootDir}/public");
    if( $? == 0){
      print "public directory created\n"
    }
  }

  if (! -e $rootDir.'/tmp'){
    system("mkdir ${rootDir}/tmp");
    if( $? == 0){
      print "tmp directory created\n"
    }
  }
  system("touch $rootDir/tmp/restart.txt");

}else{
  print "found HTML\n";
}

sub python{
  print "found python\n";
  my $venv = $rootDir.'/venv';
  system("$virtualenv -p $runtime $venv");
  if ( $? == 0 ){
    my $pip = $venv.'/bin/pip';
    system("$pip install -r $requirements");
    if ( $? != 0 ){
      die "error pip install\n";
    }
  }else {
    die "can't create virtualenv\n";
  }
}

sub node{
  print "found nodejs\n";
  system("$npm install --nodedir=$runtime --prefix $rootDir");
  if ($? != 0){
    die "error npm install\n";
  }
}
