library(ggplot2)
library(ggthemes)
library(dplyr)
library(gdata)

team_data_path <- "data/teams.csv"

lost_teams = function(teams, year){
  lost <- setdiff(filter(teams, Year==year-1)$X., filter(teams, Year==year)$X.)
  lost_team_ages <- teams[teams$X. %in% lost, ]
  group_by(lost_team_ages, X.) %>% summarize(age=n())
}

# Compute percentage loss for teams
lost_percent <- function(teams, year)
  length(setdiff(filter(teams, Year==year-1)$X., filter(teams, Year==year)$X.))/max(length(filter(teams, Year==year)$X.),1)

# Let's import teams


teams <- read.csv2(team_data_path)
# Some weirdness with Locales having spaces before/after, let's make life easier
teams$Locale <- trim(teams$Locale) 


years <- seq(2005, 2016)

compute_losses <- function(teams_sub, factor="ALL")
  data.frame(factor=factor, years=years, 'attrition pct'=sapply(years, function(year) 
    100-lost_percent(teams_sub, year)*100), 'team count'=sapply(years, function(year) 
      length(filter(teams_sub, Year==year)$X.))
  )


districts <- rbind(
  compute_losses(filter(teams, Locale=='OR' | Locale=='WA'), 'PNW'),
  compute_losses(filter(teams, Locale=='DE' | Locale=='NJ' | Locale=='PA'), 'MAR'),
  compute_losses(filter(teams, Locale=='CT' | Locale=='MA' | Locale=='ME' | Locale=='VT' | Locale=='NH'), 'NE'),
  compute_losses(filter(teams, Locale=='MI'), 'MI'),
  #compute_losses(filter(teams, Locale=='IN'), 'IN'),
  compute_losses(filter(teams, Locale=='MD' | Locale=='VA' | Locale=='DC'), 'CHS'),
  #compute_losses(filter(teams, Locale=='GA'), 'GA'),
  #compute_losses(filter(teams, Locale=='MN'), 'MN'),
  #compute_losses(filter(teams, Locale=='NC'), 'NC')
  compute_losses(teams, 'ALL')
)

p <- ggplot(districts, mapping = aes(years,attrition.pct, col=factor))


retention<- p + geom_line(size=1.06, linejoin="mitre") + scale_x_continuous(breaks = years) + scale_y_continuous(breaks=seq(0,100)) + theme_fivethirtyeight() + scale_color_tableau()+ xlab(label = "Year") +ylab(label="Retention %") + theme(legend.title=element_blank())


ggsave("images/district_retention.png", plot=retention, height=5, width=10)

anno <- read.csv("data/annotations.csv")

retention + annotate("text", x=anno$year, y=anno$y, label=anno$label, size=3, hjust=-0.05) + annotate("point", x=anno$year, y=anno$y, shape=21) 
ggsave("images/annotated_district_retention.png", height=5, width=10)


m <- ggplot(districts, mapping = aes(years,attrition.pct, group=factor))
michigan <-m + geom_line(size=1, linejoin="mitre", color="gray", alpha=0.4) + scale_x_continuous(breaks = years) + scale_y_continuous(breaks=seq(0,100)) + theme_fivethirtyeight() + scale_color_tableau()+ xlab(label = "Year") +ylab(label="Retention %") + theme(legend.title=element_blank()) + ylim(80,100) + geom_line(data=filter(districts, factor=='MI'), color="orange", size=1.06)
ggsave("images/michigan_retention.png", height=5, width=10)



regions = c("AL", "AK", "AS", "AZ", "AR", "CA", "CO", "CT", "DE", "DC", "FL", "GA", "GU", "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD", "MH", "MA", "MI", "FM", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ", "NM", "NY", "NC", "ND", "MP", "OH", "OK", "OR", "PW", "PA", "PR", "RI", "SC", "SD", "TN", "TX", "UT", "VT", "VA", "VI", "WA", "WV", "WI", "WY")
us_teams <- filter(teams,Year>=2004, Locale %in% regions)



losses = compute_losses(us_teams)
for(locale in regions){
  losses <- rbind(losses, compute_losses(filter(us_teams, Locale==locale), locale))
}


losses$lower = losses$attrition.pct -  min*scale(losses$team.count, center = 0)
losses$upper = losses$attrition.pct +  min*scale(losses$team.count, center = 0)
min = 5

ggplot(losses[losses$factor!='ALL',]) + geom_ribbon(mapping=aes(ymin=lower, ymax=upper, x=years, y=attrition.pct, group=factor), fill="blue", alpha=0.3) + facet_wrap(facets="factor") + theme_fivethirtyeight() + scale_color_tableau()+ xlab(label = "Year") +ylab(label="Retention %") + theme(legend.title=element_blank()) + coord_cartesian(ylim=c(80,100)) + geom_line(mapping=aes(years, attrition.pct), col="blue")
ggsave("images/all_retention_with_teams.png", height=12, width=12)


retention <- losses[c("factor", "years", "attrition.pct", "team.count")]
colnames(retention) <- c("region", "year", "pct_retained", "teams")
write.csv(retention, file = "data/retention.csv")



