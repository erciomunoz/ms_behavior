{smcl}
{* *! version 1.0 February 2022}{...}
{cmd: help gdxtodta}
{hline}

{title:Title}

{phang}
{bf:Command to read GDX files from GAMS into Stata}

{title:Syntax}

{p 8 17 2}
{cmd:gdxtodta}
{cmd:,}
{cmd:scenarios(}{it:scenario}{cmd:)}
{cmd:cgepath(}{it:cgepath}{cmd:)}
{cmd:gamspath(}{it:gamspath}{cmd:)}
[
{cmdab:sets}
{cmdab:parameters}
{cmdab:variables}
{cmdab:gms}
]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt scenarios()}}specifies the name of the gdx file that will be read.{p_end}

{synopt:{opt cgepath()}}specifies a work directory. A txt file will be saved here and the folders with gdx files need to be located here.{p_end}

{synopt:{opt gamspath()}}specifies the directory in which GAMS is installed.{p_end}

{synopt:{opt sets:}}gdx files contain sets, parameters and variables. This option is to read only sets.{p_end}

{synopt:{opt parameters:}}gdx files contain sets, parameters and variables. This option is to read only parameters.{p_end}

{synopt:{opt variables:}}gdx files contain sets, parameters and variables. This option is to read only variables.{p_end}

{synopt:{opt gms:}}option to save a GMS file.{p_end}


{title:Description}


{cmd:gdxtodta} calls GAMS (through the operative system) to open a gdx file and save it as txt. It then imports this text file and save it as a dta file.

This is done because Stata does not read gdx files but can read csv or txt files. Hence, we can save our gdx file as txt to be imported in Stata. 

This can be done directly from GAMS or from within Stata by sending a command through the operative system as done here using the Stata command "shell" or "!". This command temporarily invoke the operating system to call gdxdump in GAMS. 

GDXDUMP is a tool to write scalars, sets, parameters (tables), variables and equations from a GDX file formatted as a GAMS program with data statements to standard output, GMS or CSV files. 
 

{title:Saved results}

{pstd}
{cmd:gdxtodta} saves the following files: 

- A txt file with a name starting with the word "dump" followed by the scenario name.
- A dta file with a name starting with "CGE Parameters" followed by the scenario name.
- A dta file with a name starting with "CGE Sets" followed by the scenario name.
- A dta file with a name starting with "CGE Variables" followed by the scenario name.
- Only one of these three dta files is saved when the option sets, parameters, or variables are used. 

{title:Examples}

{cmd:. gdxtodta, scenarios("BAU") cgepath("$cgeapppath") gamspath("$gamspath")}

{title:Authors}
{p}
{p_end}

{pstd}
Ercio Munoz, Poverty and Equity GP, the World Bank.

{pstd}
Email: {browse "mailto:emunozsaavedra@worldbank.org":emunozsaavedra@worldbank.org}

{title:Notes}
This ado file is a simplified version of the gdxtodta.ado written by Israel Osorio (iosoriorodarte@worldbank.org) as part of the GIDD model.



