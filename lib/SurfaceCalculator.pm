package SurfaceCalculator;
use strict;
use warnings;
use Cwd;
use Image::Magick;
use Bio::Phylo::Util::Logger;
require Exporter;

# this is a purely procedural module that exports one
# subroutine, i.e. the usage would be:
# use SurfaceCalculator 'calc_surface';
# my $surface = calc_surface($path);
our @ISA = qw'Exporter';
our @EXPORT_OK = qw'calc_surface';

my $log = Bio::Phylo::Util::Logger->new;


# computes the percentage of black pixels (to 2 decimal places)
# for an image that will be processed to hard black/white
sub calc_surface {
	my $inpath = shift || shift @ARGV;
	my $cwd = getcwd;
	my $infile = "$cwd/$inpath";	
	$log->debug("going to compute surface cover of $infile");
	
	# instantiate Image::Magick object (needs to be able to handle $extension!)
	my $image = Image::Magick->new;
	$image->Read($infile);
	$log->debug("read infile using Image::Magick");
	
	# this makes the image hard black/white
	$image->Posterize('levels' => 2);
	$log->debug("made image hard black/white");
	
	# this makes the pixels 0/1
	$image->Set('monochrome' => 'true');
	$log->debug("set pixels to monochrome");

	# compute dimensions
	my $width = $image->Get('width');
	my $height = $image->Get('height');
	$log->debug("computed dimensions");

	# iterate over all pixels
	$log->debug("going to count black pixels");
	my ( $black, $total );
	for my $y ( 1 .. $height ) {
		for my $x ( 1 .. $width ) {
			
			# sample pixel at $x,$y
			my @pixel = $image->GetPixel( 'y' => $y - 1, 'x' => $x - 1 );
			
			# compute average brightness, is either 0 or 1
			my $mean = ( $pixel[0] + $pixel[1] + $pixel[2] + 0 ) / 3;
			$black++ if $mean;
			$total++;
		}
	}
	
	# return percentage of black pixels with two decimal points
	return sprintf "%.2f", ( 100 - ( $black / $total ) * 100 );
}

1;