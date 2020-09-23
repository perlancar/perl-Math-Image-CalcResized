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
    summary => 'Calculate resized dimensions of image/video',
};

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
        {args=>{size=>"2592x1944", resize=>"20%"}, result=>[200, "OK", "518x388"]},

        {args=>{size=>"2592x1944", resize=>"20%x40%"}, result=>[200, "OK", "518x777"]},
        {args=>{size=>"2592x1944", resize=>"20x40%"}, result=>[200, "OK", "518x777"]},

        {args=>{size=>"2592x1944", resize=>"1024"}, result=>[200, "OK", "1024x768"]},

        {args=>{size=>"2592x1944", resize=>"1024>"}, result=>[200, "OK", "1024x768"]},
        {args=>{size=>"2592x1944", resize=>"10240>"}, result=>[200, "OK", "2592x1944"]},

        {args=>{size=>"2592x1944", resize=>"1024^"}, result=>[200, "OK", "2592x1944"]},
        {args=>{size=>"2592x1944", resize=>"10240^"}, result=>[200, "OK", "10240x7680"]},

        {args=>{size=>"2592x1944", resize=>"x1024"}, result=>[200, "OK", "1365x1024"]},

        {args=>{size=>"2592x1944", resize=>"x768>"}, result=>[200, "OK", "1024x768"]},
        {args=>{size=>"2592x1944", resize=>"x7680>"}, result=>[200, "OK", "2592x1944"]},

        {args=>{size=>"2592x1944", resize=>"x768^"}, result=>[200, "OK", "2592x1944"]},
        {args=>{size=>"2592x1944", resize=>"x7680^"}, result=>[200, "OK", "10240x7680"]},

        {args=>{size=>"2592x1944", resize=>"20000x10000"}, result=>[200, "OK", "2592x1944"]},
        {args=>{size=>"2592x1944", resize=>"20000x1000"}, result=>[200, "OK", "1333x1000"]},
        {args=>{size=>"2592x1944", resize=>"100x200"}, result=>[200, "OK", "100x75"]},
        {args=>{size=>"2592x1944", resize=>"100x100"}, result=>[200, "OK", "100x75"]},

        {args=>{size=>"2592x1944", resize=>"10000x5000^"}, result=>[200, "OK", "10000x7500"]},
        {args=>{size=>"2592x1944", resize=>"5000x10000^"}, result=>[200, "OK", "13333x10000"]},
        {args=>{size=>"2592x1944", resize=>"100x100^"}, result=>[200, "OK", "2592x1944"]},

        {args=>{size=>"2592x1944", resize=>"100x100!"}, result=>[200, "OK", "100x100"]},

        {args=>{size=>"2592x1944", resize=>"10000x5000>"}, result=>[200, "OK", "2592x1944"]},
        {args=>{size=>"2592x1944", resize=>"5000x10000>"}, result=>[200, "OK", "2592x1944"]},
        {args=>{size=>"2592x1944", resize=>"3000x1000>"}, result=>[200, "OK", "2592x1944"]}, #?
        {args=>{size=>"2592x1944", resize=>"2000x1000>"}, result=>[200, "OK", "1333x1000"]},
        {args=>{size=>"2592x1944", resize=>"100x100>"}, result=>[200, "OK", "100x75"]},

        {args=>{size=>"2592x1944", resize=>"10000x5000<"}, result=>[200, "OK", "10000x7500"]},
        {args=>{size=>"2592x1944", resize=>"5000x10000<"}, result=>[200, "OK", "13333x10000"]},
        {args=>{size=>"2592x1944", resize=>"3000x1000<"}, result=>[200, "OK", "2592x1944"]}, #?
        {args=>{size=>"2592x1944", resize=>"2000x1000<"}, result=>[200, "OK", "2592x1944"]},
        {args=>{size=>"2592x1944", resize=>"100x100<"}, result=>[200, "OK", "2592x1944"]},

        {args=>{size=>"2592x1944", resize=>"1024^>"}, result=>[200, "OK", "1365x1024"]},
        {args=>{size=>"2592x1944", resize=>"10240^>"}, result=>[200, "OK", "2592x1944"]},
        {args=>{size=>"2592x1944", resize=>"1024^<"}, result=>[200, "OK", "2592x1944"]},
        {args=>{size=>"2592x1944", resize=>"10240^<"}, result=>[200, "OK", "13653x10240"]},

        {args=>{size=>"2592x1944", resize=>"^1024>"}, result=>[200, "OK", "1024x768"]},
        {args=>{size=>"2592x1944", resize=>"^10240>"}, result=>[200, "OK", "2592x1944"]},
        {args=>{size=>"2592x1944", resize=>"^1024<"}, result=>[200, "OK", "2592x1944"]},
        {args=>{size=>"2592x1944", resize=>"^10240<"}, result=>[200, "OK", "10240x7680"]},
    ],
};
sub calc_image_resized_size {
    my %args = @_;

    my $size = $args{size} or return [400, "Please specify image size"];
    $size =~ /\A(\d+)x(\d+)\z/ or return [400, "Invalid size format, please use <width>x<height> syntax"];
    my $resize = $args{resize} or return [400, "Please specify resize"];
    my ($w, $h) = ($1, $2);
    my ($longer, $shorter) = $w < $h ? ($h, $w) : ($w, $h);
    my ($w2, $h2) = ($w, $h);

    # some instructions are translated to other first
    if ($resize =~ /\A(\d+)\^([<>])\z/) {
        if ($w < $h) {
            $resize = "$1$2";
        } else {
            $resize = "x$1$2";
        }
    } elsif ($resize =~ /\A\^(\d+)([<>])\z/) {
        if ($w > $h) {
            $resize = "$1$2";
        } else {
            $resize = "x$1$2";
        }
    }

    if ($resize =~ /\A(\d+(?:\.\d*)?)%\z/) {
        $w2 = $1/100 * $w;
        $h2 = $1/100 * $h;
    } elsif ($resize =~ /\A(\d+(?:\.\d*)?)%?x(\d+(?:\.\d*)?)%\z/) {
        $w2 = $1/100 * $w;
        $h2 = $2/100 * $h;
    } elsif ($resize =~ /\A(\d+)([>^<]?)\z/) {
        my $which = $2;
        if ($which eq '>') { # shrink
            goto SKIP if $w <= $1;
        } elsif ($which eq '^' || $which eq '<') { # enlarge
            goto SKIP if $w >= $1;
        }

        $w2 = $1;
        $h2 = ($h/$w) * $w2;
    } elsif ($resize =~ /\Ax(\d+)([>^<]?)\z/) {
        my $which = $2;
        if ($which eq '>') { # shrink
            goto SKIP if $h <= $1;
        } elsif ($which eq '^' || $which eq '<') { # enlarge
            goto SKIP if $h >= $1;
        }

        $h2 = $1;
        $w2 = ($w/$h) * $h2;
    } elsif ($resize =~ /\A(\d+)x(\d+)([<>!^]?)\z/) {
        my $which = $3;
        if ($which eq '' || $which eq '>') {
            if ($which eq '>') { goto SKIP if $w <= $1 || $h <= $2 }

            if ($h2 > $2) {
                $h2 = $2;
                $w2 = ($w/$h) * $h2;
            }
            if ($w2 > $1) {
                $h2 = $1/$w2 * $h2;
                $w2 = $1;
            }
        } elsif ($which eq '^' || $which eq '<') {
            if ($which eq '<') { goto SKIP if $w >= $1 || $h >= $2 }
            if ($h2 < $2) {
                $h2 = $2;
                $w2 = ($w/$h) * $h2;
            }
            if ($w2 < $1) {
                $h2 = $1/$w2 * $h2;
                $w2 = $1;
            }
        } elsif ($which eq '!') {
            $w2 = $1;
            $h2 = $2;
        }
    } else {
        return [400, "Unrecognized resize instruction '$resize'"];
    }

  SKIP:
    [200, "OK", sprintf("%dx%d", $w2, $h2)];
}

1;
# ABSTRACT:

=head1 SEE ALSO
