package Math::Image::CalcResized;

# AUTHORITY
# DATE
# DIST
# VERSION

use 5.010001;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(calc_image_resized_size);
our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Calculate dimensions of image/video resized by ImageMagick-like geometry specification',
};

sub _calc_or_human {
    my ($action, %args) = @_;

    my $size;
    my ($w, $h);
    if ($action eq 'calc') {
        $size = $args{size} or return [400, "Please specify image size"];
        $size =~ /\A(\d+)x(\d+)\z/ or return [400, "Invalid size format, please use <width>x<height> syntax"];
        ($w, $h) = ($1, $2);
    }
    my $resize = $args{resize}; defined $resize or return [400, "Please specify resize"];
    my ($w2, $h2) = ($w, $h);
    my $human_general = "no resizing";
    my $human_specific;

    goto SKIP unless length $resize;

    # some instructions are translated to other first
    if ($resize =~ /\A(\d+)\^([<>])\z/) {
        $human_general = ($2 eq '>' ? "shrink" : "enlarge") . " shortest side to ${1}px";
        goto SKIP unless $action eq 'calc';
        if ($w < $h) {
            $resize = "$1$2";
            $human_specific = ($2 eq '>' ? "shrink" : "enlarge") . " shortest side (width) to ${1}px";
        } else {
            $resize = "x$1$2";
            $human_specific = ($2 eq '>' ? "shrink" : "enlarge") . " shortest side (height) to ${1}px";
        }
    } elsif ($resize =~ /\A\^(\d+)([<>])\z/) {
        $human_general = ($2 eq '>' ? "shrink" : "enlarge") . " longest side to ${1}px";
        goto SKIP unless $action eq 'calc';
        if ($w > $h) {
            $resize = "$1$2";
            $human_specific = ($2 eq '>' ? "shrink" : "enlarge") . " longest side (width) to ${1}px";
        } else {
            $resize = "x$1$2";
            $human_specific = ($2 eq '>' ? "shrink" : "enlarge") . " longest side (height) to ${1}px";
        }
    }

    if ($resize =~ /\A(\d+(?:\.\d*)?)%\z/) {
        $human_general = "scale to $resize";
        goto SKIP unless $action eq 'calc';
        $w2 = $1/100 * $w;
        $h2 = $1/100 * $h;
        $human_specific = "scale to $resize (${w2}px)";
    } elsif ($resize =~ /\A(\d+(?:\.\d*)?)%?x(\d+(?:\.\d*)?)%\z/) {
        $human_general = "scale width to ${1}%, height to ${2}%";
        goto SKIP unless $action eq 'calc';
        $w2 = $1/100 * $w;
        $h2 = $2/100 * $h;
        $human_specific = "scale width to ${1}% (${w2}px), height to ${2}% (${h2}px)";
    } elsif ($resize =~ /\A(\d+)([>^<]?)\z/) {
        my $which = $2;
        if ($which eq '>') { # shrink
            $human_general = "shrink width to ${1}px";
            goto SKIP unless $action eq 'calc';
            goto SKIP if $w <= $1;
        } elsif ($which eq '^' || $which eq '<') { # enlarge
            $human_general = "enlarge width to ${1}px";
            goto SKIP unless $action eq 'calc';
            goto SKIP if $w >= $1;
        } else {
            $human_general = "set width to ${1}px";
            goto SKIP unless $action eq 'calc';
        }

        $w2 = $1;
        $h2 = ($h/$w) * $w2;
        $human_specific = $human_general;
    } elsif ($resize =~ /\Ax(\d+)([>^<]?)\z/) {
        my $which = $2;
        if ($which eq '>') { # shrink
            $human_general = "shrink height to ${1}px";
            goto SKIP unless $action eq 'calc';
            goto SKIP if $h <= $1;
        } elsif ($which eq '^' || $which eq '<') { # enlarge
            $human_general = "enlarge height to ${1}px";
            goto SKIP unless $action eq 'calc';
            goto SKIP if $h >= $1;
        } else {
            $human_general = "set height to ${1}px";
            goto SKIP unless $action eq 'calc';
        }

        $h2 = $1;
        $w2 = ($w/$h) * $h2;
        $human_specific = $human_general;
    } elsif ($resize =~ /\A(\d+)x(\d+)([<>!^]?)\z/) {
        my $which = $3;
        if ($which eq '' || $which eq '>') {
            if ($which eq '>') {
                $human_general = "shrink image to fit inside ${1}x${2}";
                goto SKIP unless $action eq 'calc';
                goto SKIP if $w <= $1 || $h <= $2;
            }

            $human_general = "fit image inside ${1}x${2}";
            goto SKIP unless $action eq 'calc';

            if ($h2 > $2) {
                $h2 = $2;
                $w2 = ($w/$h) * $h2;
            }
            if ($w2 > $1) {
                $h2 = $1/$w2 * $h2;
                $w2 = $1;
            }
            $human_specific = $human_general;
        } elsif ($which eq '^' || $which eq '<') {
            if ($which eq '<') {
                $human_general = "enlarge image to fit ${1}x${2} inside it";
                goto SKIP unless $action eq 'calc';
                goto SKIP if $w >= $1 || $h >= $2;
            }

            $human_general = "fit image to fit ${1}x${2} inside it";
            goto SKIP unless $action eq 'calc';

            if ($h2 < $2) {
                $h2 = $2;
                $w2 = ($w/$h) * $h2;
            }
            if ($w2 < $1) {
                $h2 = $1/$w2 * $h2;
                $w2 = $1;
            }
            $human_specific = $human_general;
        } elsif ($which eq '!') {
            $human_general = "set dimension to ${1}x${2}";
            goto SKIP unless $action eq 'calc';

            $w2 = $1;
            $h2 = $2;
            $human_specific = $human_general;
        }
    } else {
        return [400, "Unrecognized resize instruction '$resize'"];
    }

  SKIP:
    if ($action eq 'human') {
        [200, "OK", $human_general];
    } else {
        [200, "OK", sprintf("%dx%d", $w2, $h2), {
            'func.human_general' => $human_general,
            'func.human_specific' => $human_specific,
        }];
    }
}

$SPEC{calc_image_resized_size} = {
    v => 1.1,
    summary => 'Given size of an image (in WxH, e.g. "2592x1944") and ImageMagick-like resize instruction (e.g. "1024p>"), calculate new resized image',
    args => {
        size => {
            summary => 'Image/video size, in <width>x<height> format, e.g. 2592x1944',
            schema => ['str*', match=>qr/\A\d+x\d+\z/],
            req => 1,
            pos => 0,
            description => <<'_',

_
        },
        resize => {
            summary => 'Resize instruction, follows ImageMagick format',
            schema => 'str*',
            req => 1,
            pos => 1,
            description => <<'_',

Resize instruction can be given in several formats:

    Syntax                     Meaning
    -------------------------- ----------------------------------------------------------------
    ""                         No resizing.

    SCALE"%"                   Height and width both scaled by specified percentage.
    SCALEX"%x"SCALEY"%"        Height and width individually scaled by specified percentages. (Only one % symbol needed.)

    WIDTH                      Width given, height automagically selected to preserve aspect ratio.
    WIDTH">"                   Shrink width if larger, height automagically selected to preserve aspect ratio.
    WIDTH"^"                   Enlarge width if smaller, height automagically selected to preserve aspect ratio.

    "x"HEIGHT                  Height given, width automagically selected to preserve aspect ratio.
    "x"HEIGHT">"               Shrink height if larger, width automagically selected to preserve aspect ratio.
    "x"HEIGHT"^"               Enlarge height if smaller, width automagically selected to preserve aspect ratio.

    WIDTH"x"HEIGHT             Maximum values of height and width given, aspect ratio preserved.
    WIDTH"x"HEIGHT"^"          Minimum values of height and width given, aspect ratio preserved.
    WIDTH"x"HEIGHT"!"          Width and height emphatically given, original aspect ratio ignored.
    WIDTH"x"HEIGHT">"          Shrinks an image with dimension(s) larger than the corresponding width and/or height argument(s).
    WIDTH"x"HEIGHT"<"          Shrinks an image with dimension(s) larger than the corresponding width and/or height argument(s).

    NUMBER"^>"                 Shrink shortest side if larger than number, aspect ratio preserved.
    NUMBER"^<"                 Enlarge shortest side if larger than number, aspect ratio preserved.
    "^"NUMBER">"               Shrink longer side if larger than number, aspect ratio preserved.
    "^"NUMBER"<"               Enlarge longer side if larger than number, aspect ratio preserved.

Currently unsupported:

    AREA"@"                    Resize image to have specified area in pixels. Aspect ratio is preserved.
    X":"Y                      Here x and y denotes an aspect ratio (e.g. 3:2 = 1.5).

Ref: <http://www.imagemagick.org/script/command-line-processing.php#geometry>

_
        },
    },
    examples => [
        {args=>{size=>"2592x1944", resize=>""}, naked_result=>"2592x1944"},

        {args=>{size=>"2592x1944", resize=>"20%"}, naked_result=>"518x388"},

        {args=>{size=>"2592x1944", resize=>"20%x40%"}, naked_result=>"518x777"},
        {args=>{size=>"2592x1944", resize=>"20x40%"}, naked_result=>"518x777"},

        {args=>{size=>"2592x1944", resize=>"1024"}, naked_result=>"1024x768"},

        {args=>{size=>"2592x1944", resize=>"1024>"}, naked_result=>"1024x768"},
        {args=>{size=>"2592x1944", resize=>"10240>"}, naked_result=>"2592x1944"},

        {args=>{size=>"2592x1944", resize=>"1024^"}, naked_result=>"2592x1944"},
        {args=>{size=>"2592x1944", resize=>"10240^"}, naked_result=>"10240x7680"},

        {args=>{size=>"2592x1944", resize=>"x1024"}, naked_result=>"1365x1024"},

        {args=>{size=>"2592x1944", resize=>"x768>"}, naked_result=>"1024x768"},
        {args=>{size=>"2592x1944", resize=>"x7680>"}, naked_result=>"2592x1944"},

        {args=>{size=>"2592x1944", resize=>"x768^"}, naked_result=>"2592x1944"},
        {args=>{size=>"2592x1944", resize=>"x7680^"}, naked_result=>"10240x7680"},

        {args=>{size=>"2592x1944", resize=>"20000x10000"}, naked_result=>"2592x1944"},
        {args=>{size=>"2592x1944", resize=>"20000x1000"}, naked_result=>"1333x1000"},
        {args=>{size=>"2592x1944", resize=>"100x200"}, naked_result=>"100x75"},
        {args=>{size=>"2592x1944", resize=>"100x100"}, naked_result=>"100x75"},

        {args=>{size=>"2592x1944", resize=>"10000x5000^"}, naked_result=>"10000x7500"},
        {args=>{size=>"2592x1944", resize=>"5000x10000^"}, naked_result=>"13333x10000"},
        {args=>{size=>"2592x1944", resize=>"100x100^"}, naked_result=>"2592x1944"},

        {args=>{size=>"2592x1944", resize=>"100x100!"}, naked_result=>"100x100"},

        {args=>{size=>"2592x1944", resize=>"10000x5000>"}, naked_result=>"2592x1944"},
        {args=>{size=>"2592x1944", resize=>"5000x10000>"}, naked_result=>"2592x1944"},
        {args=>{size=>"2592x1944", resize=>"3000x1000>"}, naked_result=>"2592x1944"}, #?
        {args=>{size=>"2592x1944", resize=>"2000x1000>"}, naked_result=>"1333x1000"},
        {args=>{size=>"2592x1944", resize=>"100x100>"}, naked_result=>"100x75"},

        {args=>{size=>"2592x1944", resize=>"10000x5000<"}, naked_result=>"10000x7500"},
        {args=>{size=>"2592x1944", resize=>"5000x10000<"}, naked_result=>"13333x10000"},
        {args=>{size=>"2592x1944", resize=>"3000x1000<"}, naked_result=>"2592x1944"}, #?
        {args=>{size=>"2592x1944", resize=>"2000x1000<"}, naked_result=>"2592x1944"},
        {args=>{size=>"2592x1944", resize=>"100x100<"}, naked_result=>"2592x1944"},

        {args=>{size=>"2592x1944", resize=>"1024^>"}, naked_result=>"1365x1024"},
        {args=>{size=>"2592x1944", resize=>"10240^>"}, naked_result=>"2592x1944"},
        {args=>{size=>"2592x1944", resize=>"1024^<"}, naked_result=>"2592x1944"},
        {args=>{size=>"2592x1944", resize=>"10240^<"}, naked_result=>"13653x10240"},

        {args=>{size=>"2592x1944", resize=>"^1024>"}, naked_result=>"1024x768"},
        {args=>{size=>"2592x1944", resize=>"^10240>"}, naked_result=>"2592x1944"},
        {args=>{size=>"2592x1944", resize=>"^1024<"}, naked_result=>"2592x1944"},
        {args=>{size=>"2592x1944", resize=>"^10240<"}, naked_result=>"10240x7680"},
    ],
};
sub calc_image_resized_size {
    _calc_or_human('calc', @_);
}

$SPEC{image_resize_notation_to_human} = {
    v => 1.1,
    summary => 'Translate ImageMagick-like resize notation (e.g. "720^>") to human-friendly text (e.g. "shrink shortest side to 720px")',
    args => {
        resize => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
    },
    examples => [
        {
            args => {resize=>''}, naked_result=>'no resizing',
        },

        {
            args => {resize=>'50%'}, naked_result=>'scale to 50%',
        },
        {
            args => {resize=>'50%x50%'}, naked_result=>'scale width to 50%, height to 50%',
        },

        {
            args => {resize=>'720'}, naked_result=>'set width to 720px',
        },
        {
            args => {resize=>'720>'}, naked_result=>'shrink width to 720px',
        },
        {
            args => {resize=>'720^'}, naked_result=>'enlarge width to 720px',
        },

        {
            args => {resize=>'x720'}, naked_result=>'set height to 720px',
        },
        {
            args => {resize=>'x720>'}, naked_result=>'shrink height to 720px',
        },
        {
            args => {resize=>'x720^'}, naked_result=>'enlarge height to 720px',
        },

        {
            args => {resize=>'640x480'}, naked_result=>'fit image inside 640x480',
        },
        {
            args => {resize=>'640x480^'}, naked_result=>'fit image to fit 640x480 inside it',
        },
        {
            args => {resize=>'640x480>'}, naked_result=>'shrink image to fit inside 640x480',
        },
        {
            args => {resize=>'640x480<'}, naked_result=>'enlarge image to fit 640x480 inside it',
        },
        {
            args => {resize=>'640x480!'}, naked_result=>'set dimension to 640x480',
        },

        {
            args => {resize=>'720^>'}, naked_result=>'shrink shortest side to 720px',
        },
        {
            args => {resize=>'720^<'}, naked_result=>'enlarge shortest side to 720px',
        },
        {
            args => {resize=>'^720>'}, naked_result=>'shrink longest side to 720px',
        },
        {
            args => {resize=>'^720<'}, naked_result=>'enlarge longest side to 720px',
        },
    ],
};
sub image_resize_notation_to_human {
    _calc_or_human('human', @_);
}

1;
# ABSTRACT:

=head1 SEE ALSO
