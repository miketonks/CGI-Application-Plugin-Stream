
use strict;

use Test::More tests => 3;
use Test::Requires qw(Plack::Loader LWP::UserAgent);
use Test::TCP;
use CGI::PSGI;

# temp for dev only
use lib '/home/mike/github/CGI--Application/lib';

BEGIN {
  use_ok('CGI::Application::Plugin::Stream');
}


test_tcp(
    client => sub {
        my $port = shift;
        my $ua = LWP::UserAgent->new;
        my $res = $ua->get("http://127.0.0.1:$port/");
        my $test_name = "with fh: Content-Disposition and filename headers are correct";
		is($res->headers->{'content-disposition'}, 'attachment; filename="test_file_to_stream.txt"', $test_name);
        is($res->content_type, 'text/plain');
    },
    server => sub {
        my $port = shift;
        Plack::Loader->auto(port => $port)->run(sub {
        	my $env = shift;
            my $cgiapp = StreamTest->new({ QUERY => CGI::PSGI->new($env) });
            return $cgiapp->run_as_psgi;
	    });
    },
);

# commented for now...

# Testing with a file handle

#my $app = StreamTest->new();
#$app->with_fh();
#
#$content_sent = $stdout->read;
#
#$test_name = "with fh: Content-Disposition and filename headers are correct";
#like($content_sent, qr/Content-Disposition: attachment; filename="FILE"/i,$test_name);
#
#$test_name    = 'with fh: Content-type detected correctly by File::MMagic';
#like($content_sent, qr!Content-Type: text/plain!i, $test_name);
#
#$test_name    = 'with fh: correct Content-Length  header found';
#like($content_sent, qr/Content-Length: 29/i,$test_name);
#
## Testing with a file
#$app = StreamTest->new();
#$app->run();
#
#$content_sent = $stdout->read;
#$test_name = "Content-Disposition and filename headers are correct";
#like($content_sent, qr/Content-Disposition: attachment; filename="test_file_to_stream.txt"/i,$test_name);
#
#$test_name = 'Content-type detected correctly by File::MMagic';
#like($content_sent, qr!Content-Type: text/plain!i, $test_name);
#
#$test_name = 'correct Content-Length header found';
#like($content_sent, qr/Content-Length: 29/i,$test_name);
#
####
#
#$test_name = 'Setting a custom Content-Length';
#$app = StreamTest->new();
#$app->header_props(Content_Length => 1 );
#$app->with_fh();
#$content_sent = $stdout->read;
#like($content_sent, qr/Content-Length: 1/i,$test_name);
#
####
#
#$test_name = 'Setting a custom -Content-Length';
#$app = StreamTest->new();
#$app->header_props(-Content_Length => 4 );
#$app->with_fh();
#$content_sent = $stdout->read;
#like($content_sent, qr/Content-Length: 4/i,$test_name);
#
####
#
#$test_name = 'Setting a custom type';
#$app = StreamTest->new();
#$app->header_props(type => 'jelly/bean' );
#$app->with_fh();
#$content_sent = $stdout->read;
#like($content_sent, qr/jelly/i,$test_name);
#
####
#
#$test_name = 'Setting a custom -type';
#$app = StreamTest->new();
#$app->header_props(-type => 'recumbent/bicycle' );
#$app->with_fh();
#$content_sent = $stdout->read;
#like($content_sent, qr/recumbent/i,$test_name);
#
####
#
#$test_name = 'Setting a custom attachment';
#$app = StreamTest->new();
#$app->header_props(attachment => 'save_the_planet_from_the_humans.txt' );
#$app->with_fh();
#$content_sent = $stdout->read;
#like($content_sent, qr/save_the_planet/i,$test_name);
#
####
#
#$test_name = 'Setting a custom -type';
#$app = StreamTest->new();
#$app->header_props(-attachment => 'do_some_yoga.mp3' );
#$app->with_fh();
#$content_sent = $stdout->read;
#like($content_sent, qr/yoga/i,$test_name);
#
####
#
#$test_name = 'Setting a non-attachment header is preserved';
#$app = StreamTest->new();
#$app->header_props(-dryer => 'clothes_line' );
#$app->with_fh();
#$content_sent = $stdout->read;
#like($content_sent, qr/dryer/i,$test_name);
#
####
#
#$test_name = 'Setting a explicit byte Content-Length at least doesn\'t die';
#$app = StreamTest->new();
#$app->with_bytes();
#$content_sent = $stdout->read;
#like($content_sent, qr/Content-type/i,$test_name);


#################

package StreamTest;
use base 'CGI::Application';
use CGI::Application::Plugin::Stream (qw/stream_file/);

sub setup {
    my $self = shift;
    $self->run_modes([qw/start with_fh with_bytes/])
}


sub start {
    my $self = shift;
warn "start <<<<<<<<<<<<<<<<<<<<<<<<<<<";
    return $self->stream_file('t/test_file_to_stream.txt');
}

sub with_fh  {
    my $self = shift;
warn "with_fh <<<<<<<<<<<<<<<<<<<<<<<<<<<";
    my $fh;
    open($fh,'<t/test_file_to_stream.txt') || die;
    return $self->stream_file($fh);
}

sub with_bytes  {
    my $self = shift;
    return $self->stream_file('t/test_file_to_stream.txt',2048);
}

1;
