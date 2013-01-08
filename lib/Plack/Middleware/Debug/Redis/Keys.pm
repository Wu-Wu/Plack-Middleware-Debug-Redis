package Plack::Middleware::Debug::Redis::Keys;

use strict;
use v5.10.1;
use Redis 1.955;
use parent 'Plack::Middleware::Debug::Base';
use Plack::Util::Accessor qw/server password db redis_handle/;

our $VERSION = '0.01';

sub prepare_app {
    my $self = shift;

    $self->server('localhost:6379') unless defined $self->server;
    $self->db(0) unless defined $self->db;

    my @opts = (
        server    => $self->server,
        reconnect => 60,
        encoding  => undef,
        debug     => 0,
    );
    push @opts, (password => $self->password) if $self->password;

    $self->redis_handle(Redis->new(@opts));
}

sub run {
    my ($self, $env, $panel) = @_;

    $panel->title('Redis::Keys');
    $panel->nav_title($panel->title);

    return sub {
        my ($res) = @_;

        my ($keyz, $ktype, $klen);
        $self->redis_handle->select($self->db);
        my @keys = $self->redis_handle->keys('*');
        $panel->nav_subtitle('DB #' . $self->db . ' (' . scalar(@keys) . ')');

        for my $key (sort @keys) {
            $ktype = uc($self->redis_handle->type($key));

            given ($ktype) {
                when ('HASH')   { $klen = $self->redis_handle->hlen($key);   }
                when ('LIST')   { $klen = $self->redis_handle->llen($key);   }
                when ('STRING') { $klen = $self->redis_handle->strlen($key); }
                when ('ZSET')   { $klen = $self->redis_handle->zcard($key);  }
                when ('SET')    { $klen = $self->redis_handle->scard($key);  }
                default         { $klen = undef;                }
            }

            $keyz->{$key} = $ktype . ($klen ? ' (' . $klen . ')' : '');
        }

        $self->redis_handle->quit;
        $panel->content($self->render_hash($keyz));
    };
}

1; # End of Plack::Middleware::Debug::Redis::Keys
__END__

=pod

=head1 NAME

Plack::Middleware::Debug::Redis::Keys - Redis keys debug panel

=head1 SYNOPSIS

    # inside your psgi app
    enable 'Debug',
        panels => [
            [ 'Redis::Keys', server => 'redis.example.com:6379', db => 3 ],
        ];

=head1 DESCRIPTION

Stub documentation for Plack::Middleware::Debug::Redis, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

=head1 OPTIONS

This debug panel define the following options:

=head2 server

Hostname and port of redis server instance. Default value is 'localhost:6379'.

=head2 password

Password to authenticate on redis server instance in case of enables redis' option B<requirepass>.

=head3 db

Redis database number to get statistic for keys. Default value is 0.

=head1 SEE ALSO

L<Plack::Middleware::Debug>

L<Redis>

=head1 AUTHOR

Anton Gerasimov, E<lt>chim@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Anton Gerasimov

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
