#!/usr/bin/perl

use warnings;
use strict;

use Term::Cap;
use POSIX;

my $termios = new POSIX::Termios; $termios->getattr;
my $ospeed = $termios->getospeed;
my $t = Tgetent Term::Cap { TERM => undef, OSPEED => $ospeed };
my ($norm, $bold, $under) = map { $t->Tputs($_,1) } qw/me md us/;

use News::NNTPClient;
use YAML qw'LoadFile DumpFile';

use Email::Simple;

use Getopt::Long;
Getopt::Long::Configure qw'bundling';

#my $parser = new MIME::Parser;

my $verbose;
my $help;
my $all;

my $result = GetOptions("verbose|v" => \$verbose,
                        "help|h" => \$help,
                        "all|a" => \$all);

sub DisplayHelp {
    print "${under}${bold}NNTPMonitor${norm}\n\n";
    print "Perl-Script to send mails if certain keywords are found in Usenet-Groups via NNTP\n";
    print "The first run will NOT trigger events. All subsequent runs will trigger only on newer hits.\n\n";
    print "Usage: $0 [-v] [-h] [-a]\n\n";
    print "\t${bold}-v, --verbose${norm}\n\t\tBe verbose\n";
    print "\t${bold}-h, --help${norm}\n\t\tDisplay this help screen\n";
    print "\t${bold}-a, --all${norm}\n\t\tTrigger on all found hits, not just on all new hits since last run. ${bold}Caution:${norm} Will take long to run and probably put heavy strain on the Newsserver and your mailbox.\n";
    print "\n";
    exit 0;
}


if ($help) {
    DisplayHelp();
}

if (!-e 'config.yaml') {
    die "Config file ${bold}config.yaml${norm} not found!\n";
}

my ($config, $triggers) = LoadFile('config.yaml');

if (!$config->{NNTP}) {
    die "NNTP-Server not found. Please check ${bold}config.yaml${norm}!\n";
}

my $news;
if ($config->{NNTPPort}) {
    $news = new News::NNTPClient($config->{NNTP},$config->{NNTPPort});
} else {
    $news = new News::NNTPClient($config->{NNTP});
}

if ($config->{NNTPUser} and $config->{NNTPPass}) {
    $news->authinfo($config->{NNTPUser},$config->{NNTPPass});
}

# Need to be 1 second since epoch so that it will be recognised as timestamp :)
my $lastrun = 1;

if (-e 'lastrun') {
    open(LASTRUN,'<','lastrun');
    $lastrun = <LASTRUN>;
    chomp($lastrun);
    close(LASTRUN);
} else {
    my $time = time();
    open(LASTRUN,'>','lastrun');
    print LASTRUN $time;
    close(LASTRUN);
    if (!$all) {
        exit 0;
    }
}

if ($all) {
    $lastrun = 1;
}

my $maxtimestamp = $lastrun;

my @newnews = $news->newnews($lastrun);

for my $mid (@newnews) {
    chomp($mid);
    my $headertext = $news->head($mid);
    my $header = Email::Simple->new(join('',@$headertext));
 #   my $header = $parser->parse_data($headertext);
    if ($header->header('Control')) {
        # Control message, skip it!
        next;
    }
    my $newsgroups = $header->header('Newsgroups');
    chomp($newsgroups);
    my @newsgroups = split(/\s*,\s*/,$newsgroups);
    my $date;
    if ($header->header('NNTP-Posting-Date')) {
        $date = $header->header('NNTP-Posting-Date');
    } else {
        $date = $header->header('Date');
    }
    chomp($date);

    my $article = Email::Simple->new(join('',@{$news->article($mid)}));
    
    1;
    
}

1;