# The .eye files under lib/Acme are treated essentially the same
# as .pm files. To achieve that we derive a new My::Builder class,
# overriding the find_pm_files method, as shown below.
# An alternative may be to use the pm_files parameter.
# Using _find_file_by_type below is naughty but I don't see an
# easy alternative because M::B does not understand .eye files.
# Suggestions welcome.

use strict;
use Module::Build;

print <<'CAMEL_GREETING';
                   ######
    #####        #########
##########      ###########
 ##########    #############
   #######   ################
  ######## ###################
  ####### #####################
  #############################
   #############################
   ##############################
    #############################
     ######################### ##
       ## ############### #### ##
          ####  ########   ### #
          ###   #### ###   ###
          ###  ##### ##     ##
          ###  ####  ##     ##
          ##   #     ##     ##
          ##    #    #      #
          ##     #  #       #
          #       ###       #
          #      ## ##      #
         ##    ####  #     ##
       ####               ####
CAMEL_GREETING

my $class = Module::Build->subclass(
   class => 'My::Builder',
   code => q{
      sub find_pm_files {
         my $self = shift;
         return { ( %{$self->_find_file_by_type('pm',  'lib')},
                    %{$self->_find_file_by_type('eye', 'lib')} ) };
      }
   }
);

my $m = $class->new(
   module_name =>     'Acme::EyeDrops',
   license =>         'perl',
   requires =>        { 'perl' => '5.005_03' },
   build_requires =>  { 'Module::Build' => 0.24 }
);
$m->create_build_script;
