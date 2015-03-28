#!/usr/bin/perl -w
use Config::Simple;
use Cwd;
use FindBin;
$AbsPath = $FindBin::RealBin.'/';

die "parameter error\n" unless ($#ARGV == 0);
$rootDir = $ARGV[0];

$cfg = new Config::Simple("${AbsPath}conf/app.conf");
$virtualenv = $cfg->param('VIRTUALENV_PATH');
$npm = $cfg->param('NPM_PATH');

$runtimeFile = $rootDir.'/runtime.txt';
if (-e $runtimeFile) {
  $cfg = new Config::Simple("${AbsPath}conf/runtime.conf");
  %cfgRuntime = $cfg->vars();
  open RUNTIME, "<", $runtimeFile or die $!;
  $language = <RUNTIME>;
  chomp $language;
  #print "language: $language , $cfgRuntime{$language}\n";
  if(exists $cfgRuntime{$language}){
    $runtime = $cfgRuntime{$language};
  }elsif(system("which $language")==0){
    $runtime = `which $language`;
  }else{
    die "error runtime $language not found\n";
  }
  print "found runtime $runtime";
  
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
