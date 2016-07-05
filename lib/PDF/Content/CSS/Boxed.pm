use v6;

role PDF::Content::CSS::Boxed[$of-type, $default=0] {
    my subset DuckType of Any where { .defined && $_ ~~  $of-type}
    has DuckType ($.top, $.left, $.bottom, $.right) is rw;
    submethod BUILD(:$!top = $default,
                    :$!right = $!top,
                    :$!bottom = $!top,
                    :$!left = $!right) {
    }
    sub boxed($a) {
        my %box;
        %box<top>     = $_ with $a[0];
        %box<right>   = $_ with $a[1];
        %box<bottom>  = $_ with $a[2];
        %box<left>    = $_ with $a[3];
        %box;
    }
    method COMPOSE {
        my $class = self;
        use MONKEY-TYPING;

        for List, Array {
            .^add_method( $class.^name, method {
                $class.new( |boxed(self) );
            })
        }
        Hash.^add_method( $class.^name, method {
            $class.new( |self );
        });
        given $of-type {
            when Numeric {
                Int.^add_method( $class.^name, method {
                                        $class.new( :top(self.Rat) );
                                   });
                Rat.^add_method( $class.^name, method {
                                       $class.new( :top(self) );
                                   });
            }
            when Str {
                Str.^add_method( $class.^name, method {
                    $class.new( :top(self) );
                });
            }
        }
    }
}
