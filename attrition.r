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


years <- seq(2005, 2016)

compute_losses <- function(teams_sub, factor="ALL")
  data.frame(factor=factor, years=years, 'attrition pct'=sapply(years, function(year) 
    100-lost_percent(teams_sub, year)*100)
  )


districts <- rbind(
  compute_losses(filter(teams, Locale=='OR' | Locale=='WA'), 'PNW'),
  compute_losses(filter(teams, Locale=='DE' | Locale=='NJ' | Locale=='PA'), 'MAR'),
  compute_losses(filter(teams, Locale=='CT' | Locale=='MA' | Locale=='ME' | Locale=='VT' | Locale=='NH'), 'NE'),
  compute_losses(filter(teams, Locale=='MI'), 'MI'),
  #compute_losses(filter(teams, Locale=='IN'), 'IN'),
  compute_losses(filter(teams, Locale=='MD' | Locale=='VA' | Locale=='DC'), 'CHS'),
  #compute_losses(filter(teams, Locale=='GA'), 'GA'),
  #compute_losses(filter(teams, Locale=='NC'), 'NC'),
  compute_losses(teams, 'ALL')
)

p <- ggplot(districts, mapping = aes(years,attrition.pct, col=factor))


retention<- p + geom_line(size=1.06, linejoin="mitre") + scale_x_continuous(breaks = years) + scale_y_continuous(breaks=seq(0,100)) + theme_fivethirtyeight() + scale_color_tableau()+ xlab(label = "Year") +ylab(label="Retention %") + theme(legend.title=element_blank())


ggsave("plot.png", plot=retention, height=5, width=10)

anno <- read.csv("annotations.csv")

retention + annotate("text", x=anno$year, y=anno$y, label=anno$label, size=3, hjust=-0.05) + annotate("point", x=anno$year, y=anno$y, shape=21) 
ggsave("annotated-retention.png", height=5, width=10)


regions = c("AL", "AK", "AS", "AZ", "AR", "CA", "CO", "CT", "DE", "DC", "FL", "GA", "GU", "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD", "MH", "MA", "MI", "FM", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ", "NM", "NY", "NC", "ND", "MP", "OH", "OK", "OR", "PW", "PA", "PR", "RI", "SC", "SD", "TN", "TX", "UT", "VT", "VA", "VI", "WA", "WV", "WI", "WY")
us_teams <- filter(teams,Year>=2004, Locale %in% regions)



losses = compute_losses(us_teams)
for(locale in regions){
  losses <- rbind(losses, compute_losses(filter(us_teams, Locale==locale), locale))
}



retention <- losses[c("factor", "years", "attrition.pct")]
colnames(retention) <- c("region", "year", "pct_retained")
write.csv(retention, file = "retention.csv")

