#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Data::Kanji::Kanjidic 'parse_kanjidic';
use File::Slurper 'read_lines';
use Lingua::JA::Moji ':all';
binmode STDOUT, ":encoding(utf8)";
my $kdicfile = '/home/ben/data/edrdg/kanjidic';
my $unihanfile = '/home/ben/data/unihan/Unihan_Readings.txt';
my $kdic = parse_kanjidic ($kdicfile);
my $unih = parse_uni_readings ($unihanfile);
compare_kdic_unih ($kdic, $unih);
exit;

sub parse_uni_readings
{
    my ($unihanfile) = @_;
    my %unih;
    my @lines = read_lines ($unihanfile);
    for my $line (@lines) {
	if ($line =~ /^U\+([0-9a-fA-F]+)\s+kJapanese(Kun|On)\s+(.*)$/) {
	    my $kanji = unicode2kanji ($1);
	    my $type = lc ($2);
	    my $readings = $3;
	    if ($unih{$kanji}{$type}) {
		warn "Duplicate $kanji $type $readings";
	    }
	    my @r = split /\s+/, $readings;
	    if ($type eq 'on') {
		@r = map {$_ = romaji2kana ($_, {wapuro => 1},) } @r;
	    }
	    else {
		@r = map {$_ = romaji2hiragana ($_, {wapuro => 1},) } @r;
	    }
	    $unih{$kanji}{$type} = \@r;
	}
    }
    return \%unih;
}

sub compare_kdic_unih
{
    my ($kdic, $unih) = @_;
    for my $k (sort keys %$kdic) {
	if (! $unih->{$k}) {
	    print "No entry for $k in $unihanfile.\n";
	    next;
	}
	compare_entries ($k, $kdic->{$k}{onyomi}, $unih->{$k}{on});
	compare_entries ($k, $kdic->{$k}{kunyomi}, $unih->{$k}{kun});
    }
}

sub compare_entries
{
    my ($k, $kon, $uon) = @_;
    my %kon;
    my %uon;
    for (@$kon) {
	s/\W//g;
	$kon{$_} = 1;
    }
    for (@$uon) {
	$uon{$_} = 1;
    }
    for (@$uon) {
	if (! $kon{$_}) {
	    print "$k $_ is in Unihan but not kanjidic.\n";
	}
    }
    for (sort keys %kon) {
	if (! $uon{$_}) {
	    print "$k $_ is in kanjidic but not Unihan.\n";
	}
    }
}

sub unicode2kanji
{
    my ($hex) = @_;
    my $kanji = chr (hex ($hex));
    return $kanji;
}
