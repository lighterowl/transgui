#!/usr/bin/env perl

# Converts transgui custom translation files to standard gettext .po, given a
# .pot file as a template to insert the translations to.
# This surely won't match everything 1-to-1 but hopefully provides a good
# starting point.

use strict;
use warnings;
use utf8;

binmode( STDOUT, ":encoding(UTF-8)" );

sub do_open {
  ( my $path, my $sub ) = @_;
  open( my $fh, '<:encoding(UTF-8)', $path )
      or die "Can't open $path : $!";
  $sub->($fh);
  close($fh);
  return;
}

sub new_entry {
  return {
    comments => [],
    msgctxt  => [],
    msgid    => [],
    msgstr   => []
  };
}

sub read_template {
  my $pot_file = shift;
  my @po_entries;

  do_open(
    $pot_file,
    sub {
      my $fh        = shift;
      my $cur_entry = new_entry();
      my $dest;
      while (<$fh>) {
        chomp;
        if ( $_ eq '' ) {
          push @po_entries, $cur_entry;
          $cur_entry = new_entry();
          next;
        }

        if (/^#/) {
          push @{ $cur_entry->{comments} }, substr( $_, 1 );
        }
        elsif (/^"(.*?)"$/) {
          push @{ $cur_entry->{$dest} }, $1;
        }
        elsif (/^(msgctxt|msgid|msgstr)/) {
          $dest = $1;
          $_ =~ /"(.*?)"$/;
          push @{ $cur_entry->{$dest} }, $1;
        }
      }
    }
  );

  return @po_entries;
}

sub gen_langfile_msgid {
  my $msgid = shift;
  return join( '', map { (s/\\n/~/gr) } @{$msgid} );
}

sub gen_msgid_hash {
  my $po_entries = shift;
  my $rv         = {};
  for my $entry ( @{$po_entries} ) {
    my $msgid = gen_langfile_msgid( $entry->{msgid} );
    $rv->{$msgid} = $entry;
  }
  return $rv;
}

sub langfile_to_msgstr {
  ( my $lang_file, my $po_entries ) = @_;
  my $msgid_hash = gen_msgid_hash($po_entries);
  do_open(
    $lang_file,
    sub {
      my $fh = shift;
      while (<$fh>) {
        my $msgid;
        my $msgstr;
        if (/^"(.*?)"="(.*?)"$/) {
          $msgid  = $1;
          $msgstr = $2;
        }
        elsif (/^(.*?)=(.*?)$/) {
          $msgid  = $1;
          $msgstr = $2;
        }

        if ( defined($msgid) and defined($msgstr) ) {
          $msgid  =~ s,\\,\\\\,g;
          $msgstr =~ s,\\,\\\\,g;

          my $entry          = $msgid_hash->{$msgid};
          my @decoded_msgstr = split( /\s*~\s*/, $msgstr );
          if ( defined($entry) ) {
            $entry->{msgstr} = [ @decoded_msgstr ];
          }
          else {
            $entry = new_entry();
            $entry->{msgid} = [ $msgid ];
            $entry->{msgstr} = [ @decoded_msgstr ];
            push @{$po_entries}, $entry;
          }
        }
      }
    }
  );
  return;
}

sub print_msg_array {
  ( my $name, my $content ) = @_;
  return if ( scalar( @{$content} ) == 0 );

  print "${name} ";
  print "\"$_\"\n" for ( @{$content} );

  return;
}

sub print_po_entries {
  my $entries = shift;
  for my $entry ( @{$entries} ) {
    print "#" . $_ . "\n" for ( @{ $entry->{comments} } );
    for my $ma ( 'msgctxt', 'msgid', 'msgstr' ) {
      print_msg_array( $ma, $entry->{$ma} );
    }
    print "\n";
  }
  return;
}

die "Usage: $0 template.pot langfile.xyz" unless @ARGV == 2;

( my $pot_file, my $lang_file ) = @ARGV;

my @po_entries = read_template($pot_file);
langfile_to_msgstr( $lang_file, \@po_entries );

print_po_entries( \@po_entries )
