package Plack::Middleware::Debug::Redis::Keys;

# ABSTRACT: Redis keys debug panel

use strict;
use warnings;
use feature ':5.10';
use parent qw(Plack::Middleware::Debug::Base Plack::Middleware::Debug::Redis);

# VERSION
# AUTHORITY

sub prepare_app {
    my ($self) = @_;

    $self->redis_connect;
}

sub run {
    my ($self, $env, $panel) = @_;

    $panel->title('Redis::Keys');
    $panel->nav_title($panel->title);

    return sub {
        my ($res) = @_;

        my ($keyz, $ktype, $klen);
        $self->redis->select($self->db);
        my @keys = $self->redis->keys('*');
        $panel->nav_subtitle('DB #' . $self->db . ' (' . scalar(@keys) . ')');

        for my $key (sort @keys) {
            $ktype = uc($self->redis->type($key));

            given ($ktype) {
                when ('HASH')   { $klen = $self->redis->hlen($key);   }
                when ('LIST')   { $klen = $self->redis->llen($key);   }
                when ('STRING') { $klen = $self->redis->strlen($key); }
                when ('ZSET')   { $klen = $self->redis->zcard($key);  }
                when ('SET')    { $klen = $self->redis->scard($key);  }
                default         { $klen = undef;                      }
            }

            $keyz->{$key} = $ktype . ($klen ? ' (' . $klen . ')' : '');
        }

        $panel->content($self->render_hash($keyz));
    };
}

1; # End of Plack::Middleware::Debug::Redis::Keys

__END__

=pod

=head1 SYNOPSIS

    # inside your psgi app
    enable 'Debug',
        panels => [
            [ 'Redis::Keys', instance => 'redis.example.com:6379', db => 3 ],
        ];

=head1 DESCRIPTION

Plack::Middleware::Debug::Redis::Keys extends Plack::Middleware::Debug by adding redis server keys debug panel.
Panel displays available keys in the redis database and its type.

    coy:knows:pseudonoise:codes             STRING (9000)
    six:slimy:snails:sailed:silently        LIST (35)
    eleven:benevolent:elephants             HASH (17)
    two:tried:and:true:tridents             SET (101)
    tie:twine:to:three:tree:twigs           ZSET (66)

Also in brackets displays key-type specific data. For I<STRING> keys it's key length in bytes; for I<HASH> - number of fields
in a hash; for I<LIST> - length of a list (number of items); for I<SET> and I<ZSET> - number of members in a set.

This panel might be added several times for different databases. Just add it again to Plack Debug panels and provide another
database number.

=head1 METHODS

=head2 prepare_app

See L<Plack::Middleware::Debug>

=head2 run

See L<Plack::Middleware::Debug>

=head2 redis_connect

See L<Plack::Middleware::Debug::Redis>

=head2 redis

See L<Plack::Middleware::Debug::Redis>

=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/Wu-Wu/Plack-Middleware-Debug-Redis/issues>

=head1 SEE ALSO

L<Plack::Middleware::Debug::Redis>

L<Plack::Middleware::Debug>

L<Redis>

=cut
