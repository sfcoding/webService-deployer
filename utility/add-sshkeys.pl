#!/usr/bin/perl -w
use strict;
use warnings;

my $SOURCE_SSH = shift or die 'username or full path of the authorized_keys needed';
my $DEST_SSH = '/home/git/.ssh/authorized_keys';

if (! -f $SOURCE_SSH){
  $SOURCE_SSH = "/home/$SOURCE_SSH/.ssh/authorized_keys";
}
my $key = `sed -n 's/\\(ssh-rsa .*\\)/\\1/p' $SOURCE_SSH`;

my $num = 0;
foreach my $i (split /\n/, $key){
  if (!`grep '$i' $DEST_SSH`) {
    $num++;
    `echo '$i' >> $DEST_SSH`;
  }
}

print "$num keys added\n";
