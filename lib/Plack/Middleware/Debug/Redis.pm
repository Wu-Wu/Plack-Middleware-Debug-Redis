package Plack::Middleware::Debug::Redis;

# ABSTRACT: Extend Plack::Middleware::Debug with Redis panels

use strict;
use warnings;
use Carp ();
use Redis 1.955;
use Plack::Util::Accessor qw/instance password db reconnect every debug encoding redis/;

# VERSION
# AUTHORITY

sub redis_connect {
    my ($self, $args) = @_;

    my $croak = sub { Carp::croak $_[0] };

    my %options = (
        debug     => $self->debug     || 0,
        reconnect => $self->reconnect || 10,
        every     => $self->every     || 100,
    );

    $options{password} = $self->password if $self->password;

    my $instance = $self->_parse_instance($self->instance);

    if ($instance->{unix}) {
        $croak->("Nonexistent redis socket ($instance->{thru})!") unless -e $instance->{thru} && -S _;
    }

    $options{ $instance->{unix} ? 'sock' : 'server' } = $instance->{thru};

    $self->db($self->db || 0);

    my $_handle;
    eval { $_handle = Redis->new(%options) };
    $croak->("Cannot get redis handle: $@") if $@;

    $self->redis($_handle);
}

sub _parse_instance {
    my ($self, $instance) = @_;

    my $params = { unix => 0, thru => '127.0.0.1:6379' };

    # slightly improved piece of code from Redis.pm by Pedro Melo (cpan:MELO)
    CHANCE: {
        last CHANCE unless $instance;

        if ($instance =~ m,^(unix:)?(?<socketpath>/.+)$,i) {
            $params->{thru} = $+{socketpath};
            $params->{unix} = 1;
            last CHANCE;
        }
        if ($instance =~ m,^((tcp|inet):)?(?<srvname>.+)$,i) {
            my ($server, $port) = ($+{srvname}, undef);
            ($server, $port)    = split /:/, $server;
            $params->{thru}     = lc($server) . ':' . (($port && ($port > 0 && $port <= 65535)) ? $port : '6379');
        }
    }

    $params;
}

1; # End of Plack::Middleware::Debug::Redis

__END__

=pod

=head1 SYNOPSIS

    # inside your psgi app
    use Plack::Builder;

    my $app = sub {[
        200,
        [ 'Content-Type' => 'text/html' ],
        [ '<html><body>OK</body></html>' ]
    ]};
    my $redis_host = 'redi.example.com:6379';

    builder {
        mount '/' => builder {
            enable 'Debug',
                panels => [
                    [ 'Redis::Info', server => $redis_host ],
                    [ 'Redis::Keys', server => $redis_host, db => 3 ],
                ];
            $app;
        };
    };

=head1 DESCRIPTION

This distribution extends Plack::Middleware::Debug with some Redis panels. At the moment, the following panels
available:

=head1 PANELS

=head2 Redis::Info

Diplay panel with generic Redis server information which is available by the command INFO.
See L<Plack::Middleware::Debug::Redis::Info> for additional information.

=head2 Redis::Keys

Diplay panel with keys Redis server information. See L<Plack::Middleware::Debug::Redis::Keys>
for additional information.

=head1 METHODS

=head2 redis_connect

=head2 redis

=head1 OPTIONS

=head2 instance

=head2 password

=head2 db

=head2 reconnect

=head2 every

=head2 debug

=head2 encoding

=head2

=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/Wu-Wu/Plack-Middleware-Debug-Redis/issues>

=head1 SEE ALSO

L<Plack::Middleware::Debug::Redis::Info>

L<Plack::Middleware::Debug::Redis::Keys>

L<Plack::Middleware::Debug>

L<Redis>

=cut
