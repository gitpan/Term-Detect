package Term::Detect;

use 5.010001;
use strict;
use warnings;
use Log::Any '$log';

our $VERSION = '0.03'; # VERSION

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(detect_terminal);

sub detect_terminal {
    my ($flag) = @_;
    $flag //= "";

    return undef unless $ENV{TERM};

    my $info = {};

  DETECT:
    {
        if ($flag =~ /p/) {
            my $out = `pstree -As $$`;
            my @p = split /---/, $out;
            my $proc = $p[-4] // ''; # -1 is pstree, -2 is perl, -3 is shell
            #say "D:out=$out, proc=$proc";
            if ($proc ~~ [qw/gnome-terminal guake xfce4-terminal mlterm lxterminal/]) {
                $info->{emulator_software} = $proc;
                $info->{emulator_engine}   = 'gnome-terminal';
                $info->{color_depth}       = 256;
                $info->{unicode}           = 1;
                if ($proc ~~ [qw/mlterm/]) {
                    $info->{default_bgcolor} = 'ffffff';
                } else {
                    $info->{default_bgcolor} = '000000';
                }
                last DETECT;
            } elsif ($proc ~~ [qw/rxvt mrxvt/]) {
                $info->{emulator_software} = $proc;
                $info->{emulator_engine}   = 'rxvt';
                $info->{color_depth}       = 16;
                $info->{unicode}           = 0;
                $info->{default_bgcolor}   = 'd6d2d0';
                last DETECT;
            } elsif ($proc ~~ [qw/pterm/]) {
                $info->{emulator_software} = $proc;
                $info->{emulator_engine}   = 'putty';
                $info->{color_depth}       = 256;
                $info->{unicode}           = 0;
                $info->{default_bgcolor}   = '000000';
                last DETECT;
            } elsif ($proc ~~ [qw/xvt/]) {
                $info->{emulator_software} = $proc;
                $info->{emulator_engine}   = 'xvt';
                $info->{color_depth}       = 0; # only support bold
                $info->{unicode}           = 0;
                $info->{default_bgcolor}   = 'd6d2d0';
                last DETECT;
            }
        }

        if ($ENV{XTERM_VERSION}) {
            $info->{emulator_engine} = 'xterm';
            $info->{color_depth} = 256;
            $info->{default_bgcolor} = 'ffffff';
            $info->{unicode} = 0;
            last DETECT;
        }

        if ($ENV{KONSOLE_DBUS_SERVICE} || $ENV{KONSOLE_DBUS_SESSION}) {
            $info->{emulator_engine} = 'konsole';
            $info->{color_depth} = 2**24;
            $info->{default_bgcolor} = '000000';
            $info->{unicode} = 1;
            last DETECT;
        }

        unless (exists $info->{color_depth}) {
            if ($ENV{TERM} =~ /256color/) {
                $info->{color_depth} = 256;
            }
        }

    }
    $info;
}

1;
#ABSTRACT: Detect running under terminal (and get terminal emulator information)


__END__
=pod

=head1 NAME

Term::Detect - Detect running under terminal (and get terminal emulator information)

=head1 VERSION

version 0.03

=head1 SYNOPSIS

 use Term::Detect qw(detect_terminal);
 say "Running under terminal" if detect_terminal();

=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 detect_terminal([$flag]) => ANY

Return undef if not detected running under terminal.

Otherwise, return a hash of information, currently includes:

=over

=item * emulator_engine => STR

=item * emulator_software => STR

Currently Konsole and xterm can be detected through environment because they
publish some environment variables.

If $flag contains "p", will execute C<pstree> to try to find out emulator
software from parent process.

=item * color_depth => INT

Either 0 (does not support ANSI color codes), 16, 256, or 16777216 (2**24).

=item * default_bgcolor => STR (6-hexdigit RGB)

For example, any xterm is assumed to have white background (ffffff) by default,
while Konsole is assumed to have black (000000).

=item * unicode => BOOL

Whether terminal supports Unicode/wide characters.

=back

=head1 SEE ALSO

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

