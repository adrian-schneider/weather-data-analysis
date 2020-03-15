# weather-data-analysis
jma and gistemp temperature and precipitation data analysis

Install the Linear Regression cpan module using the following command:
cpanm Statistics::Regression


Linear Regression Perl module

Documentation:
https://metacpan.org/pod/Statistics::Regression

Modification (fix division by zero):
C:/Strawberry/perl/site/lib/Statistics/Regression.pm line 438
printf "%7.2f", $standarderrors[$i] ? ($theta->[$i]/$standarderrors[$i]) : 0.0;


Symbolic Links to data directories

mklink /d GISTEMP ..\WeatherDataGISTEMP
mklink /d JMA ..\WeatherDataJMA

