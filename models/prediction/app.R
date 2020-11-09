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
library(forecast)
library(ggplot2)
suppressPackageStartupMessages(library(randomForest))

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

countries <- read.csv("country_names.csv", row.names=1)
codes <- as.vector(countries$x)
names(codes) = row.names(countries)
countries <- codes

backup_arima <- function(x, xreg_p=NULL, new_xreg_p=NULL, years_p=15) {
  predictedres <- tryCatch({
    model <- auto.arima(x, xreg=xreg_p)
    if (sum(arimaorder(model))<1) {
      yr <- tsp(x)[1]:tsp(x)[2]
      gamma_model <- glm(x~poly(yr, degree=2), data=data.frame(x, yr), family=Gamma)
      new_yr <- (tsp(x)[2]+1):(tsp(x)[2]+years_p)
      poly_res <- predict(gamma_model, newdata=data.frame(yr=new_yr), type="response")
      return(ts(c(x, poly_res), start=tsp(x)[1], end=tsp(x)[2]+years_p))
      
      # do glm gamma distribution
      'gamma_model <- glm(x~., data=data.frame(xreg_p, x), family=Gamma)
      
      fit.step =step(gamma_model,
                     scope=list(upper=~.,lower=~1, trace=F) )
      fit.step$anova
      attributes(fit.step)
      selected=glm(fit.step$formula, data=data.frame(xreg_p, x), family=Gamma)
      predict(selected, newdata=data.frame(new_xreg_p), type="response")'
    }
    
    return(forecast(model, xreg=new_xreg_p, h=years_p))
  }, error = function(e) {
    # do linear regression
    start_yr = tsp(x)[1]
    result <- x
    if(is.null(xreg_p)) {
      #xreg_p <- tsp(x)[1]:tsp(x)[2]
      #new_xreg_p <- (tsp(x)[2]+1):(tsp(x)[2]+years_p)
      start_yr <- tsp(x)[2]+1
      result <- NULL
    }
    xreg_p <- cbind(xreg_p, year=tsp(x)[1]:tsp(x)[2])
    new_xreg_p <- cbind(new_xreg_p, year=(tsp(x)[2]+1):(tsp(x)[2]+years_p))
    model1 <- lm(x~., data=data.frame(x, xreg_p))
    #new_xreg_p <- rbind(xreg_p, new_xreg_p)
    pr <- predict(model1, newdata=data.frame(new_xreg_p))
    return(ts(c(result, pr), start=start_yr, end=tsp(x)[2]+years_p))
  })
  predictedres
}

goldstein_data <- read.csv("goldstein_data.csv")
#country <- "TTO"
#goldstein_data <- na.omit(goldstein_data[goldstein_data$country_code==country,])
goldstein_data <- goldstein_data[goldstein_data$year!=2020,]
#myts <- ts(goldstein_data[,c("year", "total", "weighted")])

predictors <- read.csv("country_predictors.csv")
predictors$urban_perc <- as.numeric(predictors$urban_perc)
p_vars <- subset(predictors, select=-c(country_code, year, country_name, gdp_cap, pop))
cor(p_vars, use="pairwise.complete.obs")
'predictors <- predictors[predictors$country_code==country,]
predictors <- subset(predictors, select=-c(country_code, country_name, gdp_cap, pop, gdp_cap_growth_rent, gdp_cap_growth_no_rent))

common_years <- intersect(goldstein_data$year, predictors$year)
year_choice <- min(goldstein_data$year):max(goldstein_data$year)
goldstein_data <- goldstein_data[which(goldstein_data$year %in% common_years),]
predictors <- predictors[which(predictors$year %in% year_choice),]
#predictors <- predictors[,colSums(is.na(predictors))<nrow(predictors)]
inds <- which(apply(predictors, 2, function(u) length(unique(as.character(u[!is.na(u)])))<2))
predictors <- predictors[,-c(1, inds)]
dims <- dim(predictors)
e <- matrix(rnorm(dims[1]*dims[2], mean=0, sd=1e-7), nrow=dims[1])
predictors[is.na(predictors)] <- 0
predictors <- data.matrix(predictors) + e

univariate <- ts(goldstein_data[,"weighted"], start=min(goldstein_data$year), end=max(goldstein_data$year))
decomposition <- mstl(univariate, s.window="periodic")
autoplot(decomposition)
fit <- auto.arima(univariate)
predicted <- forecast(fit, h=20)
autoplot(predicted)

fit <- auto.arima(univariate, xreg=data.matrix(predictors))'


# generate future regressors
var_extend <- function(var_i, years, year_range) { 
  var_ts <- ts(var_i, start=year_range[1], end=year_range[2])
  res <- backup_arima(var_ts, years_p=years)
  if (class(res)=="forecast") {
    res <- res$mean
  }
  as.vector(res)
}

better_apply <- function(input_pred, years, year_range) {
  output<- NULL
  for (i in 1:ncol(input_pred)) {
    output= cbind(output, var_extend(input_pred[,i], years, year_range))
  }
  colnames(output) = colnames(input_pred)
  return(output)
}

'new_xreg <- apply(predictors, 2, var_extend)

predicted <- forecast(fit, xreg=new_xreg, h=20)
autoplot(predicted)'


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Define UI 
ui <- fluidPage(

    # Application title
    titlePanel("Time Series Prediction"),

    # Sidebar
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
          sliderInput(
            "years", 
            "Number of years to predict",
            min = 1, max = 50, value = 15
          ),
        ),

        # Show a plot of the generated distribution
        mainPanel(
           plotOutput("mstlPlot"),
           plotOutput("predictionPlot")
        )
    )
)

# Define server logic
server <- function(input, output) {

    output$mstlPlot <- renderPlot({
        selection <- input$selection
        goldstein1 <- na.omit(goldstein_data[goldstein_data$country_code==selection,])
        univariate <- ts(goldstein1[,"weighted"], start=min(goldstein1$year), end=max(goldstein1$year))
        decomposition <- mstl(univariate)
        p <- autoplot(decomposition) +
          ggtitle("Trend Decomposition of Conflict") +
          xlab("Year") +
          theme(plot.title = element_text(size = 14, face = "bold"),
                text = element_text(size = 12),
                axis.title = element_text(face="bold"),
                axis.text.x=element_text(size = 11))
        p
    })
    
    output$predictionPlot <- renderPlot({
      selection <- input$selection
      years <- input$years
      
      goldstein <- na.omit(goldstein_data[goldstein_data$country_code==selection,])
      univariate <- ts(goldstein[,"weighted"], start=min(goldstein$year), end=max(goldstein$year))
      
      xpredictors <- predictors[predictors$country_code==selection,]
      xpredictors <- subset(xpredictors, select=-c(country_code, country_name, gdp_cap, pop, gdp_cap_growth_rent, gdp_cap_growth_no_rent))
      common_years <- intersect(goldstein$year, xpredictors$year)
      year_choice <- min(goldstein$year):max(goldstein$year)
      goldstein <- goldstein[which(goldstein$year %in% common_years),]
      xpredictors <- xpredictors[which(xpredictors$year %in% year_choice),]
      inds <- which(apply(xpredictors, 2, function(u) length(unique(as.character(u[!is.na(u)])))<2))
      xpredictors <- xpredictors[,-c(1, inds)]
      
      xpredictors <- na.roughfix(xpredictors)
      xpredictors <- scale(xpredictors)
      
      yrrange <- c(min(goldstein$year), max(goldstein$year))
      new_xreg <- better_apply(xpredictors, years, yrrange) #apply(xpredictors, 2, function(u) var_extend(u,years))
      predicted <- backup_arima(univariate, xreg_p=data.matrix(xpredictors), new_xreg_p=new_xreg, years_p=years)
      
      p <- autoplot(predicted) +
        ylim(0, NA) + geom_vline(xintercept=2019, color="red") +
        xlab("Year") + ylab("Weighted Sum of Negative Goldstein Scores") +
        theme(plot.title = element_text(size = 14, face = "bold"),
              text = element_text(size = 12),
              axis.title = element_text(face="bold"),
              axis.text.x=element_text(size = 11))
      p
    })
}

# Run the application 
shinyApp(ui = ui, server = server)
