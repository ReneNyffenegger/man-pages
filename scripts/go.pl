#!/usr/bin/perl
use warnings;
use strict;

use File::Find;

my %man_pages;
my $pass;
my $out_dir = '/home/rene/github/github/man-pages/out/';

main();

sub main {

  pass(1);
  pass(2);

  html_index();

}
sub pass {
  $pass = shift;

  find({
       wanted     => \&find_callback,
#      preprocess => \&find_preprocess_callback
     }, 'src/git.kernel.org/man-pages'
  );
}

# sub find_preprocess_callback {
#   
#    print "\$File::Find::dir   $File::Find::dir \n"; # directory containing file
#    print "\$File::Find::name  $File::Find::name\n"; # path of file
#    print "\$_                 $_\n";                # Name of the file (without path information)
# }

sub find_callback {

  return if $_ eq '.';

  $File::Find::prune = 1 if -d $_ and $_ !~ /^man\d$/;

#  print "\$File::Find::dir   $File::Find::dir \n"; # directory containing file
#  print "\$File::Find::name  $File::Find::name\n"; # path of file
#  print "\$_                 $_\n";                # Name of the file (without path information)
#   print "relative path      ". File::Spec -> abs2rel($File::Find::name, $root_dir), "\n";
  
  return unless $_ =~ /\.\d$/;

# print "Parsing $File::Find::name\n";
  parse_man_page($_);
}


sub parse_man_page {

  my $name_dot_section = shift;

  my $TH_seen                      = 0;
  my $last_line_was_TH             = 0;
  my $first_line_with_content_seen = 0;
  my $SH_NAME_expected             = 0;
  my $NAME_text_expected           = 0;

  if (! exists $man_pages{$name_dot_section}) {
     $man_pages{$name_dot_section} = {};
  }

  open (my $man_page_fh, '<', $name_dot_section) or die;

  while (my $line = <$man_page_fh>) {

    if ($. == 1) {
      next if $line =~ /^'\\" t\b/;
      next if $line =~ /^ *$/;
      next if $line =~ /^\\" Copyright/;
      next if $line =~ /\\t$/;
    }

    # Remove comments
      next if $line =~ m!^\.\\"!;
      $line =~ s/\\".*//;
      $line =~ s/\.$//;

      if (! $first_line_with_content_seen) {

        # First line with content should either be a .TH line or source
        # another man page with the .so instruction.
        
          if ($line =~ /^.TH/) {
             $last_line_was_TH = 1;
             my ($title_manpage, $sect, $yyyy, $mm, $dd, $src, $title_manual);
             if ( 
                  ($title_manpage, $sect, $yyyy, $mm, $dd, $src, $title_manual) = $line =~ /^.TH (\S+) +(\d) +(\d\d\d\d)-(\d\d)-(\d\d) +"([^"]*)" +"([^"]*)"/ or
                  ($title_manpage, $sect, $yyyy, $mm, $dd, $src, $title_manual) = $line =~ /^.TH (\S+) +(\d) +(\d\d\d\d)-(\d\d)-(\d\d) +(\S+) +"([^"]*)"/
                )
                {
                  $man_pages{$name_dot_section}{date} = "$yyyy-$mm-$dd";
  #               print "$yyyy-$mm-$dd\n";
                }
                else {
                #
                # Could not parse .TH...
                #
  #               print $line;
                }
            $SH_NAME_expected = 1;
          }
          elsif ($line =~ /^\.so/) {
            
            if ($pass == 1) {

              chomp $line;

             (my $page_ref = $line) =~ s!.*/(.*)!$1!;

                push @{$man_pages{$page_ref}{so_by}}, $name_dot_section; # $man_pages{$name_dot_section};
                $man_pages{$name_dot_section}{so} = $page_ref;# $man_pages{$page_ref};

            }

          }
          elsif ($line =~ /^\.if n \.pl 1000v$/) {
            next; # suffixes (7)
          }
          else {
            #
            # TODO later:
            #
            # print "$name_dot_section does not start with .TH not .so: $line ($.)\n" unless $line =~ /^\.TH/;
          }

          $first_line_with_content_seen = 1;

      }
      elsif ($SH_NAME_expected) {

        if (! $line =~ /^.SH NAME/) {
          print $name_dot_section, ': ', $line;

        }
        $SH_NAME_expected   = 0;
        $NAME_text_expected = 1;

      }
      elsif ($NAME_text_expected) {
        my ($name_pre, $name_text) = $line =~ /(.*) +\\- +(.*)/;
        $man_pages{$name_dot_section}{name_text} = $name_text;
#       print $line;
        $NAME_text_expected = 0;

      }


  }
  if ($pass == 2) {

    open my $html_fh, '>', "$out_dir/$name_dot_section.html" or die;

    my ($page_name, $section) = $name_dot_section =~ m!(.*)\.(\d)!;
    print $html_fh "$page_name ($section)\n";

    if (my $name_text = $man_pages{$name_dot_section}{name_text}) {
       print $html_fh " - <i>$name_text</i>";
    }

    if (exists $man_pages{$name_dot_section}{so_by}) {
      print $html_fh "<br> referred by:";
      for my $page_so_by ( @{$man_pages{$name_dot_section}{so_by}} ) {
         my ($n, $s) = $page_so_by =~ m!(.*)\.(\d)!;
         print $html_fh " <a href='$page_so_by.html'>$n ($s)</a>";
      }
    }
    if (exists $man_pages{$name_dot_section}{so}) {
       my ($n, $s) = $man_pages{$name_dot_section}{so} =~ m!(.*)\.(\d)!;
       print $html_fh ": see <a href='$man_pages{$name_dot_section}{so}.html'>$n ($s)</a>";
    }

    if (exists $man_pages{$name_dot_section}{date}) {
      print $html_fh "<br><b>Date:</b> $man_pages{$name_dot_section}{date}\n";
    }

    close $html_fh;

  }

}

sub html_index {

  open my $html_fh, '>', "$out_dir/index.html" or die;

  for my $name_dot_section (sort keys %man_pages) {
     print $html_fh "\n<br><a href='$name_dot_section.html'>$name_dot_section</a>";

     if (my $name_text = $man_pages{$name_dot_section}{name_text}) {
       print $html_fh ": <i>$name_text</i>";
     }
  }

  close $html_fh;
}
