library(ggplot2)
library(ggthemes)
library(dplyr)
library(gdata)

team_data_path <- "teams.csv"

# Compute percentage loss for teams
lost_percent <- function(teams, year)
  length(setdiff(filter(teams, Year==year-1)$X., filter(teams, Year==year)$X.))/length(filter(teams, Year==year)$X.)

# Let's import teams


teams <- read.csv2(team_data_path)
# Some weirdness with Locales having spaces before/after, let's make life easier
teams$Locale <- trim(teams$Locale) 


years <- seq(2006, 2015)

compute_losses <- function(teams_sub, factor="ALL")
  data.frame(factor=factor, years=years, 'attrition pct'=sapply(years, function(year) 
    lost_percent(teams_sub, year)*100)
  )


districts <- rbind(
  compute_losses(filter(teams, Locale=='OR' | Locale=='WA'), 'PNW'),
  compute_losses(filter(teams, Locale=='DE' | Locale=='NJ' | Locale=='PA'), 'MAR'),
  compute_losses(filter(teams, Locale=='CT' | Locale=='MA' | Locale=='ME' | Locale=='VT' | Locale=='NH'), 'NE'),
  compute_losses(filter(teams, Locale=='MI'), 'MI'),
  compute_losses(filter(teams, Locale=='IN'), 'IN'),
  compute_losses(teams, 'ALL')
)

p <- ggplot(districts, mapping = aes(years,attrition.pct, col=factor))


p +geom_point() + geom_line(size=1.06, linejoin="mitre") + scale_x_continuous(breaks = seq(2006,2015)) + theme_fivethirtyeight() + scale_color_tableau()+ xlab(label = "Year") +ylab(label="Attrition %") + theme(legend.title=element_blank())
