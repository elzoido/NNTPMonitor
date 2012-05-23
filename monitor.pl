#!/usr/bin/perl

use warnings;
use strict;

use News::NNTPClient;
use YAML qw'LoadFile DumpFile';

if (!-e 'config.yaml') {
    die "Config file config.yaml not found!\n";
}

my ($config, $triggers) = LoadFile('config.yaml');

if (!$config->{NNTP}) {
    die "NNTP-Server not found. Please check config.yaml!\n";
}

my $news;
if ($config->{NNTPPort}) {
    $news = new News::NNTPClient($config->{NNTP},$config->{NNTPPort});
} else {
    $news = new News::NNTPClient($config->{NNTP});
}

if ($config->{NNTPUser} and $config->{NNTPPort}) {
    $news->authinfo($config->{NNTPUser},$config->{NNTPPort});
}

my $state;

if (-e 'state.yaml') {
    ($state) = LoadFile('state.yaml');
}

1;