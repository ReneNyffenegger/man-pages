#!/usr/bin/perl
use warnings;
use strict;

use File::Find;

main();

sub main {

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

  my $path_to_man_page = shift;

  my $TH_seen                      = 0;
  my $first_line_with_content_seen = 0;

  open (my $man_page_fh, '<', $path_to_man_page) or die;

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

      unless ($first_line_with_content_seen) {

        # First line with content should either be a .TH line or source
        # another man page with the .so instruction.
        
          if ($line =~ /^.TH/) {

          }
          elsif ($line =~ /^\.so/) {

          }
          elsif ($line =~ /^\.if n \.pl 1000v$/) {
            next; # suffixes (7)
          }
          else {
            print "$path_to_man_page does not start with .TH not .so: $line ($.)\n" unless $line =~ /^\.TH/;
          }

          $first_line_with_content_seen = 1;

      }

  }

}
