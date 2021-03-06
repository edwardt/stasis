#!/usr/bin/perl -w
use strict;
use Stasis;

my $expected = qq(! => + => y => q => a
                    b
               r => c
                    d
          z => s => e
                    f
               t => g
                    h
     - => @ => u => i
                    j
               v => k
                    l
          # => w => m
                    n
               x => o
                    p
);
my $checking = 0;
my $out = "";

sub myprint {
  my $a = shift;
  if($checking) {
    $out .= $a;
  } else {
    print $a;
  }
}

if($ARGV[0] eq "--automated-test") {
  shift @ARGV;
  system ("rm -rf storefile.txt logfile.txt stasis_log");
  $checking = 1;
}
Stasis::Tinit();

my $xid = Stasis::Tbegin();
my $rid;

sub walk {
    my $from = shift;
    my $h = shift;
    my $level  = shift || 0;
    my $to = $h->{$from};
    myprint $from;
    $level += (length($from) + 4);

    if(defined $to) {
        my @tok = split ',', $to;
        my $first = 1;
        foreach my $f (@tok) {
            if($first) { myprint " => "; } else { my $n = $level; while($n--) {myprint " ";} }
            $first = 0;
            walk($f,$h,$level);
        }
    } else {
        myprint "\n";
    }
}

if(Stasis::TrecordType($xid, Stasis::ROOT_RID()) == Stasis::INVALID_SLOT()) {
    $rid = Stasis::ThashCreate($xid);
} else {
    $rid = Stasis::ROOT_RID();
}

my %hash;
tie(%hash, 'Stasis::Hash', $xid, $rid);


while(my $line = <>) {
    chomp $line;
    my @tok = split '\s+', $line;
    if($tok[0] eq "c") {
        #Stasis::ThashInsert($xid, $rid, $tok[1], $tok[2]);
	$hash{$tok[1]} = $tok[2];
    } elsif($tok[0] eq "q") {
        walk $tok[1], \%hash;
    }

}

Stasis::Tcommit($xid);
Stasis::Tdeinit();

if($checking) {
  $out eq $expected || die "\nFAIL: Output did not match.  Expected\n$expected\nGot\n$out";
  print "\nPASS: Produced expected output:\n$out";
}
