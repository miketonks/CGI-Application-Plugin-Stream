
use strict;

use Test::More tests => 25;
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
        my $res = $ua->get("http://127.0.0.1:$port/?rm=basic");
        my $test_name = "with fh: Content-Disposition and filename headers are correct";
		is($res->headers->{'content-disposition'}, 'attachment; filename="test_file_to_stream.txt"', $test_name);
        is($res->content_type, 'text/plain');
        like $res->content, qr/darcs \n/;
        is $res->content_length, 29;
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

test_tcp(
    client => sub {
        my $port = shift;
        my $ua = LWP::UserAgent->new;
        my $res = $ua->get("http://127.0.0.1:$port/?rm=with_fh");
        my $test_name = "with fh: Content-Disposition and filename headers are correct";
		is($res->headers->{'content-disposition'}, 'attachment; filename="FILE"', $test_name);
        is($res->content_type, 'text/plain');
        like $res->content, qr/darcs \n/;
        is $res->content_length, 29;
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

# setting custom content length is has a odd effect here, but it's an odd thing to do anyway!
# I'm just trying to honour the original test suite
test_tcp(
    client => sub {
        my $port = shift;
        my $ua = LWP::UserAgent->new;
        my $res = $ua->get("http://127.0.0.1:$port/?rm=custom_content_length");
        my $test_name = "custom_content_length: Content-Length and filename headers are correct";
		is($res->headers->{'content-disposition'}, 'attachment; filename="test_file_to_stream.txt"', $test_name);
        is($res->content_type, 'text/plain');
        is $res->content, 'd';
        is $res->content_length, 1;
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

test_tcp(
    client => sub {
        my $port = shift;
        my $ua = LWP::UserAgent->new;
        my $res = $ua->get("http://127.0.0.1:$port/?rm=custom_content_type");
        my $test_name = "custom_content_type: Content-Type and filename headers are correct";
		is($res->headers->{'content-disposition'}, 'attachment; filename="test_file_to_stream.txt"', $test_name);
        is($res->content_type, 'jelly/bean');
        like $res->content, qr/darcs \n/;
        is $res->content_length, 29;
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


test_tcp(
    client => sub {
        my $port = shift;
        my $ua = LWP::UserAgent->new;
        my $res = $ua->get("http://127.0.0.1:$port/?rm=custom_attachment_name");
        my $test_name = "custom_attachment_name: Content-Type and filename headers are correct";
		is($res->headers->{'content-disposition'}, 'attachment; filename="save_the_planet_from_the_humans.txt"', $test_name);
        is($res->content_type, 'text/plain');
        like $res->content, qr/darcs \n/;
        is $res->content_length, 29;
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

test_tcp(
    client => sub {
        my $port = shift;
        my $ua = LWP::UserAgent->new;
        my $res = $ua->get("http://127.0.0.1:$port/?rm=with_bytes");
        my $test_name = "with_bytes: Setting an explicit byte Content-Length at least doesn\'t die";
		is($res->headers->{'content-disposition'}, 'attachment; filename="test_file_to_stream.txt"', $test_name);
        is($res->content_type, 'text/plain');
        like $res->content, qr/darcs \n/;
        is $res->content_length, 29;
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


#################

package StreamTest;
use base 'CGI::Application';
use CGI::Application::Plugin::Stream (qw/stream_file/);

sub setup {
    my $self = shift;
    $self->run_modes([qw/basic with_fh with_bytes custom_content_length custom_content_type custom_attachment_name/])
}


sub basic {
    my $self = shift;
    return $self->stream_file('t/test_file_to_stream.txt');
}

sub with_fh {
    my $self = shift;
    my $fh;
    open($fh,'<t/test_file_to_stream.txt') || die;
    return $self->stream_file($fh);
}

sub with_bytes {
    my $self = shift;
    return $self->stream_file('t/test_file_to_stream.txt',2048);
}

sub custom_content_length {
    my $self = shift;
	$self->header_props(Content_Length => 1 );
    return $self->stream_file('t/test_file_to_stream.txt');
}

sub custom_content_type {
    my $self = shift;
	$self->header_props(-type => 'jelly/bean' );
    return $self->stream_file('t/test_file_to_stream.txt');
}

sub custom_attachment_name {
    my $self = shift;
	$self->header_props(-attachment => 'save_the_planet_from_the_humans.txt' );
    return $self->stream_file('t/test_file_to_stream.txt');
}

1;
