#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#    http://shiny.rstudio.com/
#
options(warn=-1)
suppressPackageStartupMessages(library(rsconnect))
library(shiny)
library(countrycode)
library(ggplot2)
library(plyr)
library(data.table)
'%notin%' <- Negate('%in%')

#rsconnect::deployApp()
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

conflict_data <- read.csv("conflict_data.csv")
conflict_data <- conflict_data[!is.na(conflict_data$country_code),]
conflict_data["total"] = apply(conflict_data[,c("acled_total", "ucdp_total", "gdelt_total")], 1, function(u) sum(u, na.rm=TRUE))
conflict_data["type_name"] <- mapvalues(conflict_data$event_type,
                                        from = c(14, 15, 16, 17, 18, 19, 20),
                                        to = c("Protest", "Exhibit Force Posture", "Reduce Relations", "Coerce", "Assault", "Fight", "Mass Violence"))
conflict_data["neg_goldstein"] <- mapvalues(conflict_data$event_type,
                                        from = c(14, 15, 16, 17, 18, 19, 20),
                                        to = c(6.5, 7.2, 4, 7, 9, 10, 10))


# deal with cowc and iso3c code merging
co_inds <- which(conflict_data$country_code %in% codelist$cowc & conflict_data$country_code %notin% codelist$iso3c)
iso3c_renamed <- apply(conflict_data[co_inds,], 1, function(u) countrycode(sourcevar=u[1], origin="cowc", destination="iso3c"))
new_conflict_data <- conflict_data
new_conflict_data[co_inds,1] = iso3c_renamed
new_conflict_data <- data.table(new_conflict_data)
new_conflict_data <- new_conflict_data[, lapply(.SD, sum), by=list(country_code, year, event_type, type_name)]
new_conflict_data <- data.frame(new_conflict_data)

# get mapping from country names to country codes
countries <- unique(new_conflict_data$country_code)
countries <- na.omit(countries)
country_names <- countrycode(sourcevar=countries, origin="iso3c", destination="country.name")
country_names[which(is.na(country_names))] = countries[which(is.na(country_names))]
names(countries) = country_names

# get weighted sum of goldstein scores for each year and country
goldstein_data <- new_conflict_data[,c("country_code", "year", "total", "neg_goldstein")]
goldstein_data["weighted"] <- goldstein_data$total*goldstein_data$neg_goldstein
goldstein_data <- data.table(goldstein_data[,c("country_code", "year", "total", "weighted")])
goldstein_data <- goldstein_data[, lapply(.SD, sum), by=list(country_code, year)]
goldstein_data$weighted <- goldstein_data$weighted
goldstein_data <- data.frame(goldstein_data)
write.csv(goldstein_data, "goldstein_data.csv")

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

ui <- fluidPage(

    # Application title
    titlePanel("Historical Conflict"),

    # Sidebar with a country selector 
    sidebarLayout(
        sidebarPanel(
            selectInput(
                "selection",
                "Select country",
                countries,
                selected = "AFG",
                multiple = FALSE,
                selectize = TRUE
            ),
            helpText("Number of conflicts of each type per year for the selected country."),
            helpText("GDELT CAMEO EVENT CODE CATEGORIES:"),
            helpText("14: Protest"),
            helpText("15: Exhibit Force Posture"),
            helpText("16: Reduce Relations"),
            helpText("17: Coerce"),
            helpText("18: Assault"),
            helpText("19: Fight"),
            helpText("20: Mass Violence")
        ),

        # Show a plot of the generated distribution
        mainPanel(
           plotOutput("linePlot")
        )
    ),
    
    sidebarLayout(
      sidebarPanel(
        selectInput(
          "countries",
          "Select countries",
          countries,
          selected = c("AFG", "IRN", "IRQ"),
          multiple = TRUE,
          selectize = TRUE
        ), 
        helpText("Intensity of conflict over time for the selected countries."),
        helpText("Intensity of conflict computed as weighted sum of negated Goldstein scores for events that year. ")
      ),
      
      # Show a plot of the generated distribution
      mainPanel(
        plotOutput("linePlot2")
      )
    )
)

# Define server logic
server <- function(input, output) {

    output$linePlot <- renderPlot({
        selection <- input$selection
        conflict_country <- conflict_data[conflict_data$country_code==selection,]
        p <- ggplot(conflict_country, aes(year, total, group=type_name, color=type_name)) + 
            geom_point(size=2.4) +
            geom_line(size=1.2) +
            ggtitle("Number of Conflicts by Year") + 
            theme(plot.title = element_text(size = 14, face = "bold"),
                  text = element_text(size = 12),
                  axis.title = element_text(face="bold"),
                  axis.text.x=element_text(size = 11),
                  legend.title = element_text(size=12, face="bold")) +
            xlab("Year") + ylab("Number of Conflicts") +
            labs(color="Type of Conflict")
            #geom_smooth(method="loess", alpha=0.13)
        p
    })
    
    output$linePlot2 <- renderPlot({
      countries <- input$countries
      conflict_countries <- goldstein_data[goldstein_data$country_code %in% countries,]
      p <- ggplot(conflict_countries, aes(year, weighted, group=country_code, color=country_code)) + 
        #geom_point(size=2.4) +
        geom_line(size=1.2) +
        ggtitle("Conflict Intensity by Country over time") + 
        theme(plot.title = element_text(size = 14, face = "bold"),
              text = element_text(size = 12),
              axis.title = element_text(face="bold"),
              axis.text.x=element_text(size = 11),
              legend.title = element_text(size=12, face="bold")) +
        xlab("Year") + ylab("Weighted Sum of Negative Goldstein Scores") +
        labs(color="Country")
        #geom_smooth(method="loess", alpha=0.13)
      p
    })
}

# Run the application 
shinyApp(ui = ui, server = server)
