#!/usr/bin/perl
#
#   TODO
#      getnetent.3 / memmove.3  (NAME spans over two lines)
#
#      memmove.3  /             (Linebreak in SYNOPSIS)
#
#      CPU_SET.3                (" in SYNOPSIS?)
#
#      math_error.7             (Newlines in SYNOPSIS)
#
use warnings;
use strict;

use File::Find;
use Cwd qw(cwd getcwd);

my %man_pages;
my $pass;
my $out_dir = '/home/rene/github/github/man-pages/out/';

# arguments_test(); exit;
main();

sub main { #_{

  pass(1);
  pass(2);

  html_index();

} #_}
sub pass { #_{
  $pass = shift;

  find({
       wanted     => \&find_callback,
#      preprocess => \&find_preprocess_callback
     }, 'src/git.kernel.org/man-pages'
  );


} #_}

# sub find_preprocess_callback {
#   
#    print "\$File::Find::dir   $File::Find::dir \n"; # directory containing file
#    print "\$File::Find::name  $File::Find::name\n"; # path of file
#    print "\$_                 $_\n";                # Name of the file (without path information)
# }

sub find_callback { #_{

  return if $_ eq '.';

  $File::Find::prune = 1 if -d $_ and $_ !~ /^man\d$/;

#  print "\$File::Find::dir   $File::Find::dir \n"; # directory containing file
#  print "\$File::Find::name  $File::Find::name\n"; # path of file
#  print "\$_                 $_\n";                # Name of the file (without path information)
#   print "relative path      ". File::Spec -> abs2rel($File::Find::name, $root_dir), "\n";
  
  return unless $_ =~ /\.\d$/;

# print "Parsing $File::Find::name\n";
  parse_man_page($_)
#   if $File::Find::name =~ /bzero.3$/
  ;
} #_}

sub parse_man_page { #_{

  my $name_dot_section = shift;

  my $TH_seen                      = 0;
  my $last_line_was_TH             = 0;
  my $first_line_with_content_seen = 0;
  my $SH_NAME_expected             = 0;
  my $NAME_text_expected           = 0;
  my $NAME_text_1st_line_seen      = 0;
# my $name_of_cur_section          = 0;
  my $cur_section;
# my $is_in_SYNOPSIS               = 0;
# my $is_in_DESCRIPTION            = 0;
# my $is_in_SEE_ALSO               = 0;
  my $in_pre                       = 0;
  my $in_ul                        = 0;

  my @lines;
# my @lines_description;
# my @lines_synopsis;
# my @lines_see_also;

  if ($pass == 1) { #_{
    if (! exists $man_pages{$name_dot_section}) {
       $man_pages{$name_dot_section} = {};
    }
  } #_}

  open (my $man_page_fh, '<', $name_dot_section) or die "Could not open $name_dot_section, dir = " . getcwd();

  while (my $line = <$man_page_fh>) { #_{

    if ($. == 1) { #_{
      next if $line =~ /^'\\" t\b/;
      next if $line =~ /^ *$/;
      next if $line =~ /^\\" Copyright/;
      next if $line =~ /\\t$/;
    } #_}

    $line = encode_html($line);

    # Remove comments
      next if $line =~ m!^\.\\"!;
      $line =~ s/\\".*//;
#     $line =~ s/\.$//;    At least in .IP instructions, the dot at the end of a line cannot be removed.

      if (! $first_line_with_content_seen) { #_{

        $first_line_with_content_seen = 1;

        # First line with content should either be a .TH line or source
        # another man page with the .so instruction.
        
          if ($line =~ /^.TH/) { #_{
             $last_line_was_TH = 1;
             my ($title_manpage, $sect, $yyyy, $mm, $dd, $src, $title_manual);
             if ( 
                  ($title_manpage, $sect, $yyyy, $mm, $dd, $src, $title_manual) = $line =~ /^.TH (\S+) +(\d) +(\d\d\d\d)-(\d\d)-(\d\d) +"([^"]*)" +"([^"]*)"/ or
                  ($title_manpage, $sect, $yyyy, $mm, $dd, $src, $title_manual) = $line =~ /^.TH (\S+) +(\d) +(\d\d\d\d)-(\d\d)-(\d\d) +(\S+) +"([^"]*)"/
                )
                {
                  $man_pages{$name_dot_section}{date} = "$yyyy-$mm-$dd";
                }
                else {
                #
                # Could not parse .TH...
                #
                }
            $SH_NAME_expected = 1;
            next;
          } #_}
          elsif ($line =~ /^\.so/) { #_{
            
            if ($pass == 1) {

              chomp $line;

             (my $page_ref = $line) =~ s!.*/(.*)!$1!;

                push @{$man_pages{$page_ref}{so_by}}, $name_dot_section; # $man_pages{$name_dot_section};
                $man_pages{$name_dot_section}{so} = $page_ref;# $man_pages{$page_ref};

            }

          } #_}
          elsif ($line =~ /^\.if n \.pl 1000v$/) { #_{
            next; # suffixes (7)
          } #_}
          else { #_{
            #
            # TODO later:
            #
            # print "$name_dot_section does not start with .TH not .so: $line ($.)\n" unless $line =~ /^\.TH/;
          } #_}


      } #_}
      elsif ($SH_NAME_expected) { #_{

        if (! $line =~ /^\.SH +NAME/) {
          print $name_dot_section, ': ', $line;
        }
        $SH_NAME_expected   = 0;
        $NAME_text_expected = 1;
        next;

      } #_}
      elsif ($NAME_text_expected) { #_{

        if (!$NAME_text_1st_line_seen) {
          my ($name_pre, $name_text) = $line =~ /(.*) +\\- +(.*)/;

          if ($pass == 1) {
            $man_pages{$name_dot_section}{name_text} = $name_text;
          }
          $NAME_text_1st_line_seen = 1;
          next;
        }
        if ($line =~ /^\./) {
          $NAME_text_expected = 0;
        }
        else {
          if ($pass == 1) {
            $man_pages{$name_dot_section}{name_text} .= " $line";
          }
          next;
        }

      } #_}
#     elsif ($line =~ /^.SH +SYNOPSIS\b/) {
#       $is_in_SYNOPSIS    = 1;
#       $is_in_DESCRIPTION = 0;
#       $is_in_SEE_ALSO    = 0;
#       next;
#     }
#     elsif ($line =~ /^.SH +DESCRIPTION\b/) {
#       $is_in_DESCRIPTION = 1;
#       $is_in_SYNOPSIS    = 0;
#       $is_in_SEE_ALSO    = 0;
#       next;
#     }
#     elsif ($line =~ /^.SH +SEE +ALSO\b/) {
#       $is_in_SEE_ALSO    = 1;
#       $is_in_DESCRIPTION = 0;
#       $is_in_SYNOPSIS    = 0;
#       next;
#     }
      if ($line =~ /^\.nf$/i) { #_{
      #
      # Start no-fill mode:
      #
        if ($pass == 2) {
          push @lines, '<pre>';
          $in_pre = 1;
        }
        next;
      } #_}
      elsif ($line =~ /^\.fi$/i) { #_{
      #
      # End nof-fill mode
      #
        if ($pass == 2) {
          push @lines, '</pre>';
          $in_pre = 0;
        }
        next;
      } #_}
      elsif (my ($bold) = $line =~ /^\.B +(.*)$/i) { #_{
        if ($pass == 2) {
          push @lines, "<b>$bold</b>";
        }
        next;
      } #_}
      elsif (my ($italic) = $line =~ /^\.I +(.*)$/i) { #_{
        if ($pass == 2) {
          push @lines, "<i>$italic</i>";
        }
        next;
      } #_}
      elsif (my ($rest) = $line =~ /^\.BI +(.*)$/i) { #_{
        if ($pass == 2) {

          my @args = arguments($rest);

          set_arguments_alternatively('b', 'i', \@args, \@lines);

       #  my $b = 1;

       #  my $l = '';
       #  for my $arg (@args) {

       #    if ($b) {
       #      $l .= "<b>$arg</b>"
       #    }
       #    else {
       #      $l .= "<i>$arg</i>"
       #    }
       #    $b = 1-$b;
       #  }
       #  push @lines, $l;

        }
        next;
      } #_}
      elsif (my ($ir) = $line =~ /^\.IR +(.*)$/i) { #_{
        if ($pass == 2) {

          my @args = arguments($ir);

          set_arguments_alternatively('i', '', \@args, \@lines);

       #  my $b = 1;

       #  my $l = '';
       #  for my $arg (@args) {

       #    if ($b) {
       #      $l .= "<b>$arg</b>"
       #    }
       #    else {
       #      $l .= "<i>$arg</i>"
       #    }
       #    $b = 1-$b;
       #  }
       #  push @lines, $l;

        }
        next;
      } #_}
      elsif (my ($bullet, $indent) = $line =~ /^\.IP +([^ ]+)(?: *)(.*) *$/i) { #_{
        if ($pass == 2) {

          unless ($in_ul) {
            push @lines, "<ul>";
          }
          push @lines, "<li><b>TODO: $bullet</b>\n";

          $in_ul = 1;
        }
        next;
      } #_}
      elsif (my ($rest_br) = $line =~ /^\.BR +(.*)$/) { #_{

        if (my ($func, $sect, $what_is_this) = $rest_br =~ /^ *(\S+) +\((\d?)\) *(.*)$/) {

          if ($sect) {
            push @lines, "<a href='$func.$sect.html'>$func($sect)</a>$what_is_this ";
          }
          else {
            push @lines, "<code>$func()$what_is_this</code> ";
          }
        }
        else {
           push @lines, "<code>$rest_br</code>";
        }
        next;
      } #_}
      elsif ($line =~ /^\.(PP|LP|P)$/i) { #_{
      #
      #  PP = LP = P:
      #    - Cause line break and vertical space downwards by
      #      amount of PD macro.
      #    - Reset font-size and font-shape to default (10pt roman)
      #      unless -rS option is given on command line
      #    - restore left margin and indentation
      #

        if ($pass == 2) {
          if ($in_ul) {
            push @lines, "</ul>\n";
            $in_ul = 0;
          }
          push @lines, '<p>';
        }
        next;
      } #_}
      elsif ( my ($sect) = $line =~ /^\.SH +(.*)/) { #_{
        $cur_section = $sect;

        if ($pass == 2) {
          push @{$man_pages{$name_dot_section}{sections}}, $sect;
          push @lines, "<h1 id='$sect'>$sect</h1>";
        }
        next;


#       $is_in_SEE_ALSO    = 0;
#       $is_in_DESCRIPTION = 0;
#       $is_in_SYNOPSIS    = 0;

#       push @lines, "<h1>" . encode_html($sect) . "</h1>";
#       next;

      } #_}
      else { #_{
        if ($pass == 2) { #_{
          
          if ($in_pre) {
            push @lines, $line;
          }
          else {
            push @lines, "<br>$line";
          }
          next;

        } #_}

#       push @{$man_pages{$name_dot_section}{sections}{$, {$name_of_cur_section}}, $line;

#       if (my ($other_man_page) = $line =~ /^.BR +(.*)/) {
#         if 
#       }


#       if ($is_in_SYNOPSIS) {
#         push @lines_synopsis, encode_html($line);
#       }
#       elsif ($is_in_DESCRIPTION) {
#         push @lines_description, encode_html($line);
#       }
#       elsif ($is_in_SEE_ALSO) {
#         push @lines_see_also, encode_html($line);
#       }
#       else {
#         push @lines, encode_html($line);
#       }

      } #_}


  } #_}
  if ($pass == 2) { #_{

    open my $html_fh, '>', "$out_dir/$name_dot_section.html" or die;

    my ($page_name, $section) = $name_dot_section =~ m!(.*)\.(\d)!;
    print $html_fh "$page_name ($section)\n";

    if (my $name_text = $man_pages{$name_dot_section}{name_text}) { #_{
       print $html_fh " - <i>$name_text</i>";
    } #_}

    if (exists $man_pages{$name_dot_section}{so_by}) { #_{
      print $html_fh "<br> referred by:";
      for my $page_so_by ( @{$man_pages{$name_dot_section}{so_by}} ) {
         my ($n, $s) = $page_so_by =~ m!(.*)\.(\d)!;
         print $html_fh " <a href='$page_so_by.html'>$n ($s)</a>";
      }
    } #_}
    if (exists $man_pages{$name_dot_section}{so}) { #_{
       my ($n, $s) = $man_pages{$name_dot_section}{so} =~ m!(.*)\.(\d)!;
       print $html_fh ": see <a href='$man_pages{$name_dot_section}{so}.html'>$n ($s)</a>";
    } #_}

    if (exists $man_pages{$name_dot_section}{date}) { #_{
      print $html_fh "<br><b>Date:</b> $man_pages{$name_dot_section}{date}\n";
    } #_}

#   if (@lines_synopsis) {
#     print $html_fh "<h1>Synopsis</h1>";
#     for my $line (@lines_synopsis) {
#       print $html_fh "<br>$line";
#     }
#   }
#   if (@lines_description) {
#     print $html_fh "<h1>Description</h1>";
#     for my $line (@lines_description) {
#       print $html_fh "<br>$line";
#     }
#   }

    for my $line (@lines) { #_{
      print $html_fh "$line";
    } #_}

#   if (@lines_see_also) {
#     print $html_fh "<h1>See also</h1>";
#     for my $line (@lines_see_also) {
#       print $html_fh "<br>$line";
#     }
#   }

    print $html_fh "<hr><a href='index.html'>Man page index</a>";
    close $html_fh;

  } #_}

} #_}
sub encode_html { #_{
  my $text = shift;

  $text =~ s/&/&amp;/g;
  $text =~ s/</&lt;/g;
  $text =~ s/>/&gt;/g;

  return $text;

} #_}

sub arguments_test { #_{

  my @parts = arguments('"void bzero(void *" s ", size_t " n );');

  die join ' - ', @parts unless @parts eq 5;
  die unless $parts[0] eq 'void bzero(void *';
  die unless $parts[1] eq 's';
  die unless $parts[2] eq ', size_t';
  die unless $parts[3] eq 'n';
  die unless $parts[4] eq ');';

} #_}

sub arguments { #_{
  my $text = shift;

  my @ret = ();

  my $next_is_escaped = 0;
  my $within_quotes   = 0;
  my $part = '';
  my $within_unquoted_token = 0;
  
  for my $c (split //, $text) {

    if ($next_is_escaped) {
      $part .= $c;
      $next_is_escaped = 0;
    }
    elsif ($c eq '\\') {
      $next_is_escaped = 1;
    }
    elsif ($c eq '"') {

      if ($within_quotes) {
#       print "\" and within quotes, returning $part<\n";
        push @ret, $part;
        $part = '';
        $within_quotes = 0;
        $within_unquoted_token = 0;
      }
      else {
        $within_quotes = 1; 
      }
    }
    elsif ($within_quotes) {
      $part .= $c;
    }
    elsif ($c eq ' ') {
      if ($within_unquoted_token) {
#       print "_ and within_unquoted_token, returning $part<\n";
        push @ret, $part;
        $part = '';
        $within_unquoted_token = 0;

     }
    # $next_non_whitespace_starts_token = 0;
    }
    else {
      $within_unquoted_token = 1;
      $part .= $c;
    }
  }
  push @ret, $part;
  return @ret;

} #_}

sub set_arguments_alternatively { #_{
  my $tag_one   = shift;
  my $tag_two   = shift;
  my $args_ref  = shift;
  my $lines_ref = shift;

  my $toggle = 1;

  my $l = '';
  for my $arg (@$args_ref) {

    if ($toggle) {
       $l .= open_tag($tag_one) . $arg . close_tag($tag_one);
    }
    else {
       $l .= open_tag($tag_two) . $arg . close_tag($tag_two);
    }
    $toggle = 1-$toggle;
  }
  push @$lines_ref, $l;

} #_}

sub open_tag { #_{
  my $tag_name = shift;

  return '' unless $tag_name;
  return "<$tag_name>";
} #_}

sub close_tag { #_{
  my $tag_name = shift;

  return '' unless $tag_name;
  return "</$tag_name>";
} #_}

sub html_index { #_{

  open my $html_fh, '>', "$out_dir/index.html" or die;

  for my $name_dot_section (sort keys %man_pages) {
     print $html_fh "\n<br><a href='$name_dot_section.html'>$name_dot_section</a>";

     if (my $name_text = $man_pages{$name_dot_section}{name_text}) {
       print $html_fh ": <i>$name_text</i>";
     }
  }
  
  close $html_fh;
} #_}
