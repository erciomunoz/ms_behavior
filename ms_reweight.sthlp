{smcl}
{* *! version 1.0 June 2022}{...}
{cmd: help ms_reweight}
{hline}

{title:Title}

{phang}
{bf:A Reweighting-Based Tool to Link a Microsimulation Model to a Macroeconomic Model}

{title:Syntax}

{p 8 17 2}
{cmd:ms_reweight}
{cmd:,}
{cmd:age(}{it:varname}{cmd:)}
{cmd:education(}{it:varname}{cmd:)}
{cmd:gender(}{it:varname}{cmd:)}
{cmd:hhsize(}{it:varname}{cmd:)}
{cmd:iweights(}{it:varname}{cmd:)}
{cmd:country(}{it:varname}{cmd:)}
{cmd:iyear(}{it:varname}{cmd:)}
{cmd:tyear(}{it:varname}{cmd:)}
{cmd:generate(}{it:varname}{cmd:)}
{cmd:match(}{it:varname}{cmd:)}
{cmd:popdata(}{it:varname}{cmd:)}
{cmd:variant(}{it:varname}{cmd:)}
{cmd:growth(}{it:varname}{cmd:)}
{cmd:laborincome(}{it:varname}{cmd:)}
{cmd:simlaborincome(}{it:varname}{cmd:)}
[
{cmd:pid(}{it:varname}{cmd:)}
{cmd:industry(}{it:varname}{cmd:)}
{cmd:industryshares(}{it:varname}{cmd:)}
{cmd:skill(}{it:varname}{cmd:)}
{cmd:targets(}{it:varname}{cmd:)}
{cmd:foodprices(}{it:varname}{cmd:)}
{cmd:foodshares(}{it:varname}{cmd:)}
]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt age()}}specifies the name of the variable containing the age of each individual.{p_end}

{synopt:{opt education()}}specifies the name of the variable containing the education level of each individual.{p_end}

{synopt:{opt gender()}}specifies the name of the variable containing the gender of each individual.{p_end}

{synopt:{opt hhsize()}}specifies the name of a variable containing the household size.{p_end}

{synopt:{opt hid()}} specifies the name of a variable containing a unique household identifier.{p_end}

{synopt:{opt iweights()}}specifies the name of a variable containing the original survey weights.{p_end}

{synopt:{opt hhsize()}}specifies the name of a variable containing the household size.{p_end}

{synopt:{opt country()}}specifies the ISO-3 code of the country under analysis. This is used to
identify the country in the UN population projections.{p_end}

{synopt:{opt iyear()}}specifies the year of the survey data used to do the simulation.{p_end}

{synopt:{opt tyear()}} specifies the year to be simulated.{p_end}

{synopt:{opt generate()}}specifies the name of the new variable to be created containing the
new weights.{p_end}

{synopt:{opt match()}} specifies whether the user wants to match the population in the UN population
projections in the base year or what is observed in the survey.{p_end}

{synopt:{opt popdata()}}specifies the name of the data set containing the UN population projections.{p_end}

{synopt:{opt variant()}}specifies the name of the variant to be used from the UN population pro-
jections.{p_end}

{synopt:{opt targets()}}specifies the name of a matrix containing the target shares. This is op-
tional.
{p_end}

{synopt:{opt growth()}}specifies the name of a matrix containing the growth in labor income by
sector.{p_end}

{synopt:{opt laborincome()}}specifies the name of a variable containing individual-level labor
income.{p_end}

{synopt:{opt simlaborincome()}}specifies the new name of a variable to be created containing
the new labor income after applying growth rates by sector and/or skill.{p_end}

{synopt:{opt pid()}}specifies the name of a variable containing a unique individual identifier. This
variable is optional and needs to be provided only when survey weights vary within the
household.{p_end}

{synopt:{opt industry()}}specifies the name of a variable containing the industry for those who
are working. Industries need to be coded as integers starting from 1 until the total number
of industries. This is optional and needs to be used together with industryshares(matrix).{p_end}

{synopt:{opt industryshares()}}specifies the name of a matrix containing the share of the popula-
tion employed on each industry. The matrix must have as many rows as industries coded
in the data set (i.e., industry(varname)) and as many columns as skill levels coded in
the data set (i.e., skill(varname)).{p_end}

{synopt:{opt skill():}}specifies the name of the variable containing the skill level of each individual.{p_end}

{synopt:{opt foodprices()}}specifies the name of a variable containing an index of food prices.{p_end}

{synopt:{opt foodshares()}}specifies the name of a variable containing the household share of
expenditure in food items.{p_end}

{title:Description}


{cmd:ms_reweight} is a wrapper function that calls wentropy command to reweight micro-data to match population targets by age, gender, education, and industry shares.


{title:Saved results}

{pstd}
{cmd:ms_reweight} saves the following files: 

- The command generates a variable containing a new set of weights and an update variable with labor income.

{title:Examples}

{cmd:. ms_reweight, age(age) edu(calif) gender(gender) hhsize(hsize) hid(hhid) iw(weight) country("Example") iyear(2002) /// }
{cmd: tyear(2016) generate(wgtsim) match(HH) popdata("$popdata") industry(industry) shares(sectoral_targets) skill(skilled) /// }
{cmd: variant("Medium-variant") growth(growth_laborincome) laborincome(labor_income) simlaborincome(sim_labor_income) targets(shares)}

{title:Authors}
{p}
{p_end}

{pstd}
Ercio Munoz, Poverty and Equity GP, the World Bank.

{pstd}
Email: {browse "mailto:emunozsaavedra@worldbank.org":emunozsaavedra@worldbank.org}

{title:Notes}
This ado file is an adaptation of an ado file called reweight.ado written by Israel Osorio-Rodarte as part of the GIDD project.



