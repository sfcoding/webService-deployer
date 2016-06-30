#!/usr/bin/perl -w
# use strict;
# use warnings;

use Config::Simple;
use FindBin;
$AbsPath = $FindBin::RealBin . '/';

die "parameter error\n" unless ( $#ARGV == 0 );
$rootDir = $ARGV[0];

Config::Simple->import_from( "${AbsPath}post-receive.conf", \%cfg );
$virtualenv = $cfg{'VIRTUALENV_PATH'}
  or chomp( $virtualenv = `which virtualenv` );
$npm = $cfg{'NPM_PATH'} or chomp( $npm = `which npm` );

# CUSTOM SCRIPT - before
my $before_script = <"$rootDir/hooks/before*"> || 0;
if ( -f $before_script ) {
    execute_script($before_script);
}

$runtimeFile = $rootDir . '/runtime.txt';
if ( -e $runtimeFile ) {

    # %cfgRuntime = $cfg->vars();
    open RUNTIME, "<", $runtimeFile or die $!;
    $language = <RUNTIME>;
    chomp $language;

    # print "language: $language , $cfgRuntime{$language}\n";
    $runtime =
         $cfg{$language}
      or chomp( $runtime = `which $language` )
      or die "error runtime $language not found\n";

    print "found runtime $runtime\n";

    $requirements = $rootDir . '/requirements.txt';
    $package      = $rootDir . '/package.json';
    if ( -e $requirements ) {
        python();
    }
    elsif ( -e $package ) {
        node();
    }
    else {
        die "no package.json or requirement.txt found\n";
    }

    if ( !-d $rootDir . '/public' ) {
        system("mkdir ${rootDir}/public");
        print "public directory created\n";
    }

    if ( !-d $rootDir . '/tmp' ) {
        system("mkdir ${rootDir}/tmp");
        print "tmp directory created\n";
    }

    # CUSTOM SCRIPT - after
    my $after_script = <"$rootDir/hooks/after*"> || 0;
    if ( -f $after_script ) {
        execute_script($after_script);
    }

    system("touch $rootDir/tmp/restart.txt");

}
else {
    print "found PHP/HTML\n";
}

sub python {
    print "found python\n";
    my $venv = $rootDir . '/venv';
    if ( !-d $venv ) {
        system("$virtualenv -p $runtime $venv");
        die "can't create virtualenv\n" unless $? != 0;
    }
    my $pip = $venv . '/bin/pip';
    system("$pip install -r $requirements");
    if ( $? != 0 ) {
        die "error pip install\n";
    }
}

sub node {
    print "found nodejs\n";
    system("$npm install --nodedir=$runtime --prefix $rootDir");
    if ( $? != 0 ) {
        die "error npm install\n";
    }
}

sub execute_script {
    my ($file) = @_;

    system("$file");
    if ($?) {
        print "get an error try to guss the interpreter..\n";
        if ( $file =~ /.\.sh$/s ) {
            print "execute with bash\n";
            system("bash $file");
        }
        elsif ( $file =~ /.\.py$/s ) {
            print "execute with python\n";
            system("python $file");
        }
        elsif ( $file =~ /.\.js$/s ) {
            print "execute with nodejs\n";
            system("node $file");
        }
        if ($?) {
            print "error during execution\n";
        }
    }
}
