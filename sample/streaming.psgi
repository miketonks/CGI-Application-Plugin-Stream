
# sample app for PSGI streaming interface in CGI::Application::Plugin::Stream

use strict;

use lib './lib';
#use lib '../CGI--Application/lib'; # uncomment this if you're using a local github version of CGI::App for testing

use CGI::PSGI;

# specify your own file here for testing, or leave it to default (see below)
my $testfile = '/home/mike/Plack-Middleware-Debug-Log4perl-0.01.tar.gz';

# default file shipped in CAP::Stream package for testing
#my $testfile = 't/test_file_to_stream.txt' unless $testfile; 


return sub {
    my $env = shift;
    my $cgiapp = StreamTest->new({ QUERY => CGI::PSGI->new($env) });
    return $cgiapp->run_as_psgi;
};

package StreamTest;
use base 'CGI::Application';
use CGI::Application::Plugin::Stream (qw/stream_file/);

sub setup {
    my $self = shift;
    $self->run_modes([qw/start with_fh with_bytes/])
}


sub start {
    my $self = shift;
    return $self->stream_file($testfile);
}

sub with_fh  {
    my $self = shift;
    my $fh;
    open($fh,"<$testfile") || die;
    return $self->stream_file($fh);
}

sub with_bytes  {
    my $self = shift;
    return $self->stream_file($testfile,2048);
}

1;


