#!/usr/bin/perl -w
use strict;
use warnings;
use FindBin;

my $rootDir = $FindBin::RealBin;

print $rootDir. "\n";

my $before_script = <"$rootDir/hooks/before*"> || 0;
if ( -f $before_script ) {
    execute_script($before_script);
}

my $after_script = <"$rootDir/hooks/after*"> || 0 ;
if ( -f $after_script ) {
    execute_script($after_script);
}

sub execute_script {
    my ($file) = @_;

    system("$file");
    if ( $? ) {
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
        if ( $? ){
            print "error during execution\n";
        }
    }
}
