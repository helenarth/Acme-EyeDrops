# The .eye files in lib/Acme are treated essentially
# the same as the .pm file in that directory.
# To achieve that we derive a new My::Builder class,
# overriding the find_pm_files method, as shown below.
# An alternative is to use the pm_files parameter.

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
         return { ( %{$self->_find_file_by_type('pm')},
                    %{$self->_find_file_by_type('eye')} ) };
      }
   }
);

my $m = $class->new(
   module_name => 'Acme::EyeDrops',
   license => 'perl',
   requires => { perl => '5.005' },
   build_requires => { 'Module::Build' => 0.19 }
);
$m->create_build_script;
