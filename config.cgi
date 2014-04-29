#!/usr/bin/perl
#
# created by devdaily.com, for demonstration purposes only.
#
# note: this program is not secure, and must be secured by apache htaccess
#       or other security mechanisms.
#

$FILE = '/home/vaktin/repo/prentvakt.txt';

#------------------------<<  htmlDie  >>-----------------------#
#
#  print an error message to stdout, then exit
#
#--------------------------------------------------------------#

sub htmlDie 
{
  $msg = shift;
  print $msg;
  exit;
}

#-------------------<<  writeOutputFile  >>--------------------#
#
#  USAGE: writeOutputFile $filename @whatToWrite
#
#--------------------------------------------------------------#

sub writeOutputFile 
{
  my $theFilename = shift;
  my $theContents = shift;

  open (OUT, "> $theFilename") || \
    &htmlDie ("Error: Could not open output file!\n");

  my @contents = split '\n', $theContents;
  my $line;
  foreach $line (@contents)
  {
    chomp($line);
    next if ( $line =~ /^\s*$/m );
    print OUT "$line\n";
  }
  close (OUT);
}


#---------------------<<  readContents  >>--------------------#
#
#  USAGE:  @contents = &readContents(filename);
#
#--------------------------------------------------------------#

sub readContents
{
  my $fullFilename = shift;
  my @contents;
  open(FILE,$fullFilename);
  while (<FILE>)
  {
    push @contents, $_;
  }
  close(FILE);
  return @contents;
}
  
#---------------------<<  printEditForm  >>--------------------#
#
#  USAGE:  &printEditForm($header,@contents);
#
#--------------------------------------------------------------#

sub printEditForm
{
  my ($header,@contents) = @_;
  my $theContents;
  foreach $line (@contents)
  {
    next if ( $line =~ /^\s*$/m );
    $theContents = $theContents . $line;
  }
  print $query->h3($header);
  print $query->startform;
  print $query->hidden('action', "save");
  print $query->textarea(-name=>'TEXT_AREA',
        -default=>$theContents,
        -rows=>30,
        -columns=>80);
  print $query->br;
  print $query->submit(-value=>'Save Changes');
  print $query->endform;
  print $query->end_html;
}


#------------------------------#
#  1. Create a new CGI object  #
#------------------------------#

use CGI;
$query = new CGI;


#----------------------------------#
#  2. Print the doctype statement  #
#----------------------------------#

print $query->header;


#----------------------------------------------------#
#  3. Start the HTML doc, and give the page a title  #
#----------------------------------------------------#

print $query->start_html('RSS File Editor');


#---------------#
#  4. Do it. :) #
#---------------#

my $action = $query->param('action');
my $textAreaContents = $query->param('TEXT_AREA');

if ( $action eq "" )
{
  $fullFilename = $FILE;
  my @contents = &readContents($fullFilename);
  &printEditForm("Editing the RSS File",@contents);
  exit;
}
elsif ( $action eq "save" )
{
  my $fullFilename = $FILE;
  &writeOutputFile($fullFilename,$textAreaContents);
  my $header = "Editing File:  $FILE";
  $header = $header . "
(file saved)";
  my @contents = &readContents($fullFilename);
  &printEditForm($header,@contents);
  exit;
}