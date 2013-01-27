#!/usr/bin/perl
use strict;
use warnings;
use Cwd;
use Accession;
use Template;
use File::Spec;
use File::RelDir;
use Data::Dumper;
use Getopt::Long;
use Image::Magick; # image magick needs to be compiled to support $extension (i.e. --with-png, probably)
use Bio::Phylo::Util::Logger;
use SurfaceCalculator 'calc_surface';

# process command line arguments
my $extension = 'png';
my $fullsize  = 'jpg';
my ( $imagedir, $template, $outfile, $metadata, @css, @js, %icons, $verbosity, $splash );
GetOptions(
	'imagedir=s'  => \$imagedir,
	'template=s'  => \$template,
	'outfile=s'    => \$outfile,
	'metadata=s'  => \$metadata,
	'extension=s' => \$extension,
	'fullsize=s'  => \$fullsize,
	'css=s'       => \@css,
	'js=s'        => \@js,
	'icons=s'     => \%icons,
	'splash=s'    => \$splash,
	'verbose+'    => \$verbosity,	
);

# instantiate logger
my $log = Bio::Phylo::Util::Logger->new( '-class' => 'main', '-level' => $verbosity );

# give info about provided command line arguments
$log->info("imagedir ... $imagedir");
$log->info("template ... $template");
$log->info("outfile .... $outfile");
$log->info("metadata ... $metadata");
$log->info("extension .. $extension");
$log->info("fullsize ... $fullsize");
$log->info("css ........ @css");
$log->info("js ......... @js");
$log->info("icons ...... " . scalar keys %icons);

# build paths from $outfile to icon dir
for my $icon ( keys %icons ) {
	$icons{$icon} = make_relpath( $outfile => $icons{$icon} );
}

# build paths from $outfile to css, javascript and splash image
@css = map { make_relpath( $outfile => $_ ) } @css;
@js  = map { make_relpath( $outfile => $_ ) } @js;
$splash = make_relpath( $outfile => $splash );

# build path from $outfile to $imagedir
my $imagepath = make_relpath( $outfile => $imagedir );

# all accession objects are going to be keyed on their barcode (with spaces replaced by underscores)
# so that we can reconcile those accessions for which we both have images and BRAHMS records
my %accession;

# read all images in $imagedir with extension $extension
opendir my $dh, "${imagedir}/${extension}" or die $!;
while( my $entry = readdir $dh ) {
	
	# ignore other files, . and ..
	if ( $entry =~ m/(.+)\.${extension}$/ ) {
		$log->debug("going to process $entry");
		my $id = $1;
		$id =~ s/ /_/g;
		
		# make path to full size image
		my $fullpath = $entry;
		$fullpath =~ s/${extension}$/$fullsize/;
		
		# instantiate Accession object, populate with image metadata
		$accession{$id} = Accession->new( 
			'src'      => "${imagepath}/${extension}/${entry}",
			'fullsize' => "${imagepath}/${fullsize}/${fullpath}",			
			'surface'  => calc_surface( "${imagedir}/${extension}/${entry}" ),
			'barcode'  => $id,
		);
		$log->info("processed $entry");
	}
}

# read BRAHMS metadata, this is a tab-delimited file with unix line breaks
{
	my @header;
	open my $fh, '<', $metadata or die $!;
	LINE: while(<$fh>) {
		chomp;
		
		# on the first line, @header is empty so we populate it here and move on to next line
		if ( not @header ) {
			@header = split /\t/, $_;
			next LINE;
		}
		
		# populate %meta hash keyed on @header column names
		my @fields = split /\t/, $_;
		my %meta = map { $header[$_] => $fields[$_] } 0 .. $#header;
		
		# remove spaces from barcode
		$meta{'barcode'} =~ s/ /_/g;
		my $barcode  = $meta{'barcode'};
		
		# we have an image for this BRAHMS record, add metadata to it
		if ( $accession{$barcode} ) {
			$log->info("adding metadata to image $barcode");
			$accession{$barcode}->$_( $meta{$_} ) for keys %meta;
		}
		
		# no image, instantiate a new Accession
		else {
			$log->warn("no image for accession $barcode");
			$accession{$barcode} = Accession->new(%meta);
		}
	}
}

# instantiate Template Toolkit object
my $tt = Template->new;

# this will contain the produced HTML
my $output;

# populate the template
$tt->process(
	$template,
	{
		'accessions' => [ values %accession ],
		'css'        => \@css, 
		'js'         => \@js,
		'icons'      => \%icons,
		'splash'     => $splash,
	},
	\$output
);

# write produced HTML to $outfile
{
	open my $fh, '>', $outfile or die $!;
	print $fh $output;
	close $fh;
}

# computes the relative path between reference location $ref and other
# location $path
sub make_relpath {
	my ( $ref, $path ) = @_;
	$ref =~ s/[^\/]+$//;
	
	# make path to target location absolute
	if ( ! File::Spec->file_name_is_absolute($path) ) {
		$path = File::Spec->rel2abs($path);
	}
	
	# make path to reference location absolute
	if ( ! File::Spec->file_name_is_absolute($ref) ) {
		$ref = File::Spec->rel2abs($ref);
	}
	
	# instantiate reference RelDir object 
	my $reference = File::RelDir->New($ref);
	
	# compute relative path
	my $relpath = $reference->Path($path);
	$log->debug("computed relative path from $ref to $path - $relpath");
	return $relpath;
}